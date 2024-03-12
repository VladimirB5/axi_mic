// insipired by article writing a linux kernel module by Derek Molloy (derekmolloy.ie)
// and linux device drivers 3rd edition

#include <linux/init.h>           // Macros used to mark up functions e.g. __init __exit
#include <linux/module.h>         // Core header for loading LKMs into the kernel
#include <linux/device.h>         // Header to support the kernel Driver Model
#include <linux/kernel.h>         // Contains types, macros, functions for the kernel
#include <linux/fs.h>             // Header for the Linux file system support
#include <linux/uaccess.h>          // Required for the copy to user function
#include <linux/ioport.h>
#include <asm/io.h>
#include <asm/current.h>
#include <linux/interrupt.h>            // Required for the IRQ code
#include <linux/delay.h>
#include <linux/platform_device.h>
#include <linux/of_device.h>
#include <linux/sched.h>
#include <asm/siginfo.h>
#include <linux/pid_namespace.h>
#include <linux/pid.h>
#include <linux/mm.h>
#include <linux/slab.h>
#include <asm/page.h>
#include <linux/dma-mapping.h>


#define  DEVICE_NAME "axi_mic"     //< The device will appear at /dev/zed_io using this value
#define  CLASS_NAME  "microphone"         //< The device class -- this is a character device driver
#define  C_ADDR_DEV 0x50000000     // device base address
#define  C_ADDR_ENA       0x00
#define  C_ADDR_RUN       0x04
#define  C_ADDR_CHANN_A   0x08
#define  C_ADDR_CHANN_B   0x0C
#define  C_ADDR_BUFF_SIZE 0x10
#define  C_ADDR_NUM_BYTES 0x14
#define  C_ADDR_INT_ENA   0x18
#define  C_ADDR_INT_STS   0x1C
#define  C_ADDR_TEST_CTRL 0x20
#define  C_ADDR_TEST      0x24

#define num_regs 10

// spread registers into bits
// C_ADDR_ENA
#define C_BIT_ENABLE_MASK      0x00000001
#define C_BIT_ENABLE_POS       0
// C_ADDR_RUN
#define C_BIT_RUN_MASK         0x00000001
#define C_BIT_RUN_POS          0
// C_ADDR_INT_ENA
#define C_BIT_INT_ENA_MASK     0x00000001
#define C_BIT_INT_ENA_POS      0
// C_ADDR_INT_STS
#define C_BIT_STS_FIN_MASK     0x00000001
#define C_BIT_STS_FIN_POS      0
#define C_BIT_STS_ERR_MASK     0x00000002
#define C_BIT_STS_ERR_POS      1
// C_ADDR_TEST_CTRL
#define C_BIT_TEST_EN_MASK     0x00000001
#define C_BIT_TEST_EN_POS      0

#define  C_NUM_REG 9           // number of readable registers
#define  C_FRAME_SIZE          0x4000// 640 * 480 * 2

/* Use '81' as magic number */
#define AXI_MIC_MAGIC 81

#define SIGETX 45 // signal to user space

#define AXI_MIC_ENA           _IOW(AXI_MIC_MAGIC, 1, int)
#define AXI_MIC_RUN           _IOW(AXI_MIC_MAGIC, 2, int)
#define AXI_MIC_CHANN_A       _IOW(AXI_MIC_MAGIC, 3, int)
#define AXI_MIC_CHANN_B       _IOW(AXI_MIC_MAGIC, 4, int)
#define AXI_MIC_BUFF_SIZE     _IOW(AXI_MIC_MAGIC, 5, int)
#define AXI_MIC_INT_ENA       _IOW(AXI_MIC_MAGIC, 6, int)
#define AXI_MIC_INT_STS       _IOW(AXI_MIC_MAGIC, 7, int)
#define AXI_MIC_TEST_ENA      _IOW(AXI_MIC_MAGIC, 8, int)
#define AXI_MIC_USER_SIG      _IOW(AXI_MIC_MAGIC, 9, int)

MODULE_LICENSE("GPL");            ///< The license type -- this affects available functionality
MODULE_AUTHOR("Vladimir Beran");    ///< The author -- visible when you use modinfo
MODULE_DESCRIPTION("MIC on AXI bus Linux char driver");  ///< The description -- see modinfo
MODULE_VERSION("0.1");            ///< A version number to inform users

static int    majorNumber;                  ///< Stores the device number -- determined automatically
static int    numberOpens = 0;              ///< Counts the number of times the device is opened
static struct class*  axi_micClass  = NULL; ///< The device-driver class struct pointer
static struct device* axi_micDevice = NULL; ///< The device-driver device struct pointer
void * virt;
static struct task_struct *task = NULL; // 
struct resource *res;
static int    data[num_regs] = {0};    ///< Memory for the data passed to user space
static int    data_read;               /// data to be read
static unsigned long page;             // adress of first page (kernel logical address)
static unsigned int page_phys;         // adress of first page (physical address) 
//char* stuff;
//char* phy_addr;
static dma_addr_t bus_addr;

int buffer_b_active = 0;

// The prototype functions for the character driver -- must come before the struct definition
int send_sig_info(int sig, struct kernel_siginfo *info, struct task_struct *p);
static int     dev_open(struct inode *, struct file *);
static int     dev_release(struct inode *, struct file *);
static ssize_t dev_read(struct file *, char *, size_t, loff_t *);
static ssize_t dev_write(struct file *, const char *, size_t, loff_t *);
static long    dev_ioctl(struct file *, unsigned int, unsigned long);

/// Function prototype for the custom IRQ handler function -- see below for the implementation
static irq_handler_t axi_mic_irq_handler(unsigned int irq, void *dev_id, struct pt_regs *regs);

/** @brief Devices are represented as file structure in the kernel. The file_operations structure from
 *  /linux/fs.h lists the callback functions that you wish to associated with your file operations
 *  using a C99 syntax structure. char devices usually implement open, read, write and release calls
 */
static struct file_operations fops =
{
   .open = dev_open,
   .read = dev_read,
   .write = dev_write,
   .unlocked_ioctl = dev_ioctl,
   .release = dev_release,
};

// struct mydriver_dm
// {
//    void __iomem *    membase; // ioremapped kernel virtual address
//    dev_t             dev_num; // dynamically allocated device number
//    struct cdev       c_dev;   // character device
//    struct class *    class;   // sysfs class for this device
//    struct device *   pdev;    // device
//    int               irq; // the IRQ number ( note: this will NOT be the value from the DTS entry )
// };
// 
// static struct mydriver_dm dm;


static int mydriver_of_probe(struct platform_device *ofdev)
{
   int result;
   //int irq;
   //struct resource *res;

   res = platform_get_resource(ofdev, IORESOURCE_IRQ, 0);
   if (!res) {
      printk(KERN_INFO "could not get platform IRQ resource.\n");
      goto fail_irq;
   }

   // save the returned IRQ
   //dm.irq = res->start;

   printk(KERN_INFO "IRQ read form DTS entry as %d\n", res->start);
   // This next call requests an interrupt line
   result = request_irq(res->start,             // The interrupt number requested
                    (irq_handler_t) axi_mic_irq_handler, // The pointer to the handler function below
                     IRQF_TRIGGER_HIGH,   // Interrupt on rising edge (button press, not release)
                     "axi_mic_handler",    // Used in /proc/interrupts to identify the owner
                     NULL);                 // The *dev_id for shared interrupt lines, NULL is okay   
   printk(KERN_INFO "axi_mic: The interrupt request result is: %d\n", result);
// 
   return 0;

fail_irq:
   return -1;

}

static int mydriver_of_remove(struct platform_device *of_dev)
{
    free_irq(res->start, NULL);
    return 0;
}

static const struct of_device_id mydriver_of_match[] = {
   { .compatible = "xlnx,axi_mic", },
   { /* end of list */ },
};
MODULE_DEVICE_TABLE(of, mydriver_of_match);

static struct platform_driver mydrive_of_driver = {
   .probe      = mydriver_of_probe,
   .remove     = mydriver_of_remove,
   .driver = {
      .name = "axi_mic",
      .owner = THIS_MODULE,
      .of_match_table = mydriver_of_match,
   },
};

/** @brief The LKM initialization function
 *  The static keyword restricts the visibility of the function to within this C file. The __init
 *  macro means that for a built-in driver (not a LKM) the function is only used at initialization
 *  time and that it can be discarded and its memory freed up after that point.
 *  @return returns 0 if successful
 */
static int __init axi_mic_init(void){
   printk(KERN_INFO "Axi_mic : Initializing axi mic Char LKM\n");

   // Try to dynamically allocate a major number for the device -- more difficult but worth it
   majorNumber = register_chrdev(0, DEVICE_NAME, &fops);
   if (majorNumber<0){
      printk(KERN_ALERT "Axi_mic failed to register a major number\n");
      return majorNumber;
   }
   printk(KERN_INFO "Axi_mic: registered correctly with major number %d\n", majorNumber);

   // Register the device class
   axi_micClass = class_create(THIS_MODULE, CLASS_NAME);
   if (IS_ERR(axi_micClass)){                // Check for error and clean up if there is
      unregister_chrdev(majorNumber, DEVICE_NAME);
      printk(KERN_ALERT "Failed to register device class\n");
      return PTR_ERR(axi_micClass);          // Correct way to return an error on a pointer
   }
   printk(KERN_INFO "Axi_mic: device class registered correctly\n");

   // Register the device driver
   axi_micDevice = device_create(axi_micClass, NULL, MKDEV(majorNumber, 0), NULL, DEVICE_NAME);
   if (IS_ERR(axi_micClass)){               // Clean up if there is an error
      class_destroy(axi_micClass);          // Repeated code but the alternative is goto statements
      unregister_chrdev(majorNumber, DEVICE_NAME);
      printk(KERN_ALERT "Failed to create the device\n");
      return PTR_ERR(axi_micDevice);
   }
   
   // request for acces to IO
   virt=ioremap(C_ADDR_DEV, 4096);
   
   platform_driver_register(&mydrive_of_driver);
   
   // alocate 2^9 = 512 pages as a buffer for pictured from cam  
   // 2^8 - 256 - 1 frame
   page =  __get_free_pages(__GFP_DMA, 8);
   
   if (!page) {
        /* insufficient memory: you must handle this error! */
        printk(KERN_ALERT "Failed to alocate memory (pages)\n");
        return ENOMEM;
   }
   
   printk("Starting pointer:%x\n", page);
   page_phys =  __pa(page);
   printk("Starting pointer(phys):%x\n", page_phys);   
   
   //stuff = kmalloc(2097152,GFP_KERNEL);
   //stuff = kmalloc(1,GFP_KERNEL);
   //printk("I got: %zu bytes of memory\n", ksize(stuff));
   //printk("Starting pointer:%x\n", stuff);
   //phy_addr = __pa((void *) stuff);
   //printk("Starting pointer(phys):%x\n", phy_addr);
   
   //set buffers
   writel(page_phys ,virt + C_ADDR_CHANN_A);
   writel(page_phys + 0x4080, virt + C_ADDR_CHANN_B);
   writel(128 ,virt + C_ADDR_BUFF_SIZE);
   //kfree(stuff);
   
    
   writel(1 ,virt + C_ADDR_INT_ENA); // interrupt will be always on
   
   printk(KERN_INFO "AXI_mic: device class created correctly\n"); // Made it! device was initialized
   return 0;
}

/** @brief The LKM cleanup function
 *  Similar to the initialization function, it is static. The __exit macro notifies that if this
 *  code is used for a built-in driver (not a LKM) that this function is not required.
 */
static void __exit axi_mic_exit(void){
   iounmap(virt);                                          // free memory 
   printk(KERN_INFO "AXI_mic: axi lite freeing ok\n");
   //free_pages(page, 8);
   //kfree(stuff);
   platform_driver_unregister(&mydrive_of_driver);
   device_destroy(axi_micClass, MKDEV(majorNumber, 0));    // remove the device
   class_unregister(axi_micClass);                         // unregister the device class
   class_destroy(axi_micClass);                            // remove the device class
   unregister_chrdev(majorNumber, DEVICE_NAME);            // unregister the major number
   printk(KERN_INFO "AXI_mic: destroyed\n");
}

/** @brief The device open function that is called each time the device is opened
 *  This will only increment the numberOpens counter in this case.
 *  @param inodep A pointer to an inode object (defined in linux/fs.h)
 *  @param filep A pointer to a file object (defined in linux/fs.h)
 */
static int dev_open(struct inode *inodep, struct file *filep){
   numberOpens++;
   return 0;
}

/** @brief This function is called whenever device is being read from user space i.e. data is
 *  being sent from the device to the user. In this case is uses the copy_to_user() function to
 *  send the buffer string to the user and captures any errors.
 *  @param filep A pointer to a file object (defined in linux/fs.h)
 *  @param buffer The pointer to the buffer to which this function writes the data
 *  @param len The length of the b
 *  @param offset The offset if required
 */
static ssize_t dev_read(struct file *filep, char *buffer, size_t len, loff_t *offset){
   int error_count = 0;  
   
   if (len == 1) {
     data_read = readl(virt+C_ADDR_NUM_BYTES);
     error_count = copy_to_user(buffer, data, 4);
     if (error_count == 0)
       return 1;    
     else {
       printk(KERN_INFO "AXI_mic: error_count during read:%d\n", error_count);
       return 0;
     }       

   } else if (len = C_FRAME_SIZE) {
      if (buffer_b_active == 1) // b is active -> read from a
        error_count = copy_to_user(buffer, (void *) page, len);
      else
        error_count = copy_to_user(buffer, (void *) (page + 0x4080), len);
      if (error_count == 0)
        return 1;    
      else {
        printk(KERN_INFO "AXI_mic: error_count during read:%d\n", error_count);
        return 0;
      }  
   } 
   else 
     return 0;
}

/** @brief This function is called whenever the device is being written to from user space i.e.
 *  data is sent to the device from the user. The data is copied to the message[] array in this
 *  LKM using the sprintf() function along with the length of the string.
 *  @param filep A pointer to a file object
 *  @param buffer The buffer to that contains the string to write to the device
 *  @param len The length of the array of data that is being passed in the const char buffer
 *  @param offset The offset if required
 */
static ssize_t dev_write(struct file *filep, const char *buffer, size_t len, loff_t *offset){ 
   int error_count = 0; 
   //unsigned long irqs;
   //int irq;
   //int i;
   //int result;
   /*
   if (len == 1) {
     error_count = copy_from_user(data, buffer ,len); 
     writeb(data[0], virt);
   }
   if (error_count != 0) {
     printk(KERN_INFO "Zed_IO: write fail\n");
   }
   */
   return 1;
}

static long dev_ioctl(struct file *filep, unsigned int _cmd, unsigned long _arg) {  
    unsigned int data;
    switch (_cmd)
    {
        case AXI_MIC_ENA: // enable block
        {
          writel(_arg ,virt + C_ADDR_ENA);
          wmb();            
          return 0;
        }
        case AXI_MIC_RUN: // run capturing
        {
          if (_arg > 0) {
            bus_addr = dma_map_single(axi_micDevice, (void *) page, 0x4000, DMA_FROM_DEVICE);
          }
          writel(_arg ,virt + C_ADDR_RUN);
          wmb();
          return 0;
        }
        case AXI_MIC_TEST_ENA: // diagnostic control - test ena
        {    
          data = readl(virt+C_ADDR_TEST_CTRL);
          if (_arg > 0)
            data = C_BIT_TEST_EN_MASK;  // set test ena
          else     
            data = 0x00; // clear test ena
          writel(data ,virt + C_ADDR_TEST_CTRL);
          wmb();
          return 0;
        }
        case AXI_MIC_USER_SIG:
        {
          task = get_current();  
          return 0;
        }    
        default:
        {    
           printk(KERN_INFO "AXI_mic: undefined ioctl\n");
           return 1;
        }            
    }    
}

/** @brief The device release function that is called whenever the device is closed/released by
 *  the userspace program
 *  @param inodep A pointer to an inode object (defined in linux/fs.h)
 *  @param filep A pointer to a file object (defined in linux/fs.h)
 */
static int dev_release(struct inode *inodep, struct file *filep){
   return 0;
}


/** @brief The axi_mic IRQ Handler function
 *  This function is a custom interrupt handler that is attached to the GPIO above. The same interrupt
 *  handler cannot be invoked concurrently as the interrupt line is masked out until the function is complete.
 *  This function is static as it should not be invoked directly from outside of this file.
 *  @param irq    the IRQ number that is associated with the GPIO -- useful for logging.
 *  @param dev_id the *dev_id that is provided -- can be used to identify which device caused the interrupt
 *  Not used in this example as NULL is passed.
 *  @param regs   h/w specific register values -- only really ever used for debugging.
 *  return returns IRQ_HANDLED if successful -- should return IRQ_NONE otherwise.
 */
static irq_handler_t axi_mic_irq_handler(unsigned int irq, void *dev_id, struct pt_regs *regs){
   struct kernel_siginfo info;
   int int_sts;
   printk(KERN_INFO "Clear pending interrupt\n");
   int_sts = readl(virt+C_ADDR_INT_STS);
   writel(0x00000007 ,virt + C_ADDR_INT_STS);  // clear all pending interrupt
   
   //printk(KERN_INFO "Unmap_dma\n");
   // this should take care that cache will be ok
   if (int_sts == 1) { // channel A
     dma_unmap_single(axi_micDevice, bus_addr,  0x4000, DMA_FROM_DEVICE);
     bus_addr = dma_map_single(axi_micDevice, (void *) (page+0x4080), 0x4000, DMA_FROM_DEVICE);
     buffer_b_active = 1;
   } else {
     dma_unmap_single(axi_micDevice, bus_addr,  0x4000, DMA_FROM_DEVICE);
     bus_addr = dma_map_single(axi_micDevice, (void *) page, 0x4000, DMA_FROM_DEVICE);
     buffer_b_active = 0;
   }
   
   
   // send signal to user space
 
   //printk(KERN_INFO "Set signal to user space\n");
   memset(&info, 0, sizeof(struct kernel_siginfo));
   info.si_signo = SIGETX;
   info.si_code = SI_QUEUE;
   info.si_int = 1;

   if (task != NULL) {
        if(send_sig_info(SIGETX, &info, task) < 0) {
            printk(KERN_INFO "Unable to send signal\n");
        }
    }      
   
   //printk(KERN_INFO "Return handler\n");
   return (irq_handler_t) IRQ_HANDLED;      // Announce that the IRQ has been handled correctly
}

/** @brief A module must use the module_init() module_exit() macros from linux/init.h, which
 *  identify the initialization function at insertion time and the cleanup function (as
 *  listed above)
 */
module_init(axi_mic_init);
module_exit(axi_mic_exit);
