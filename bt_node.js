// Test script for btle messages

var bleno = require('bleno'); // Import Bleno, a BTLE peripheral implementation
var getopt = require('node-getopt'); // Import GetOpt, a command line argument processor
var prompts = require('prompts'); // Command line prompts

var options = new getopt([
    [''  , 'device=integer'      , 'Use interface hci<number>'],
    ['a' , 'attack=type'         , 'Specify attack type'],
    ['l' , 'log=FILE'            , 'Log to this file'],
    ['d' , 'debug'               , 'Enable verbose debug logging'],
    ['h' , 'help'                , 'display this help'],
]);
options.setHelp("Usage: node bt_node <Options>");

opt=options.parseSystem(); // Parse command line arguments

if (opt.options.help) { // If they did -h or --help
    options.showHelp(); // Show help from options.setHelp above
    process.exit(0); // Exit
}

var logfile = "none"; // Defaults - No logging
var debug_flag = false; // Defaults - Debug mode off
var attack_type = "none"; // Defaults - No attack specified
var caught_break = false; // Used for catching ctrl+c
process.on('SIGINT', function() { // Catch INT signal, and set an interrupt flag to break from loops
    console.log(">>> Caught interrupt signal <<<"); // Log the signal
    caught_break = true; // Set a flag
});
BLENO_HCI_DEVICE_ID = 0; // Defaults - First bluetooth interface
if (opt.options.debug) { debug_flag = true; } // Set options from command line args
if (opt.options.device) { BLENO_HCI_DEVICE_ID = opt.options.device; } // Set options from command line args
if (opt.options.attack) { attack_type = opt.options.attack; } // Set options from command line args
if (opt.options.log) { logfile = opt.options.log; } // Set options from command line args
if (attack_type == "acosta") {
    console.log('Attack type -> Acosta (Acts important, yells a lot, not worth listening to)');
    console.log('');
    let user_options = [
        {
            type: 'text',
            name: 'addr',
            message: 'Targer address: '
        },
        {
            type: 'text',
            name: 'service',
            message: 'Service ID to use: '
        },
        {
            type: 'text',
            name: 'char',
            message: 'Characteristic ID to use: '
        },
        {
            type: 'text',
            name: 'value',
            message: 'Value to broadcast: '
        }
    ]
    let response = await prompts(user_options);
    var target_addr = response.addr;
    var target_service = response.service;
    var target_char = response.char;
    var target_value = response.value;
    adapter_start();
    console.log('About to start broadcasting, use Ctrl+C to stop...');
    create_fake_broadcaster(target_addr,target_service,target_char,target_value);
    console.log('Single pass complete');
    process.exit(0);
}
console.log('No actions specified, quitting...');
process.exit(0);

function create_fake_broadcaster (target_addr,target_service,target_char,target_value) {
    //Setup a fake service
    bleno.address = target_addr;
    console.log('Link address changed to ' + bleno.address);
    console.log('Setting service to ' + target_service);
    console.log('Setting characteristic to ' + target_char);
    console.log('Setting value to ' + target_value);
    new bleno.PrimaryService({
        uuid : target_service,
        characteristics : [
            // Define a new characteristic within that service
            new bleno.Characteristic({
                value : target_value,
                uuid : target_char,
                properties : ['read'],
                // Send a message back to the client with the characteristic's value
                onReadRequest : function(offset, callback) {
                    console.log("Read request received");
                    callback(this.RESULT_SUCCESS, new Buffer("Echo: " + 
                            (this.value ? this.value.toString("utf-8") : "")));
                },
            })
        ]
    })
}
function adapter_start () {
    if (bleno.state != 'poweredOn') {
        console.log('Attempting to bring up Bleno instance on hci' + BLENO_HCI_DEVICE_ID);
        bleno.once('stateChange', function(state){
            if (state === 'poweredOn') {
                console.log('Bleno instance is up');
            }
            else {
                console.log('Failed to bring up Bleno instance...quitting.');
                process.exit(1);
            }
        })
    }
}
function adapter_stop () {
    // Shutdown adapter
    if (bleno.state == 'poweredOn') {
        console.log('Bringing down Bleno interface');
        bleno.once('stateChange', function(state){
            if (state === 'poweredoff') {
                console.log('Bleno instance is down');
            }
            else {
                console.log('Failed to bring down Bleno instance...quitting.');
                process.exit(1);
            }
        })
    }
}