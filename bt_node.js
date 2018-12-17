// Test script for btle messages

var bleno = require('./lib/noble');
var getopt = require('node-getopt');

var options = new getopt([
    [''  , 'device=integer'      , 'Use interface hci<number>'],
    ['l' , 'log=FILE'            , 'Log to this file'],
    ['d' , 'debug'               , 'Enable verbose debug logging'],
    ['h' , 'help'                , 'display this help'],
]);
options.setHelp("Usage: node bt_node <Options>")

opt=options.parseSystem(); // Parse command line arguments

if (opt.options.help) { // If they did -h or --help
    options.showHelp() // Show help from options.setHelp above
    process.exit(0) // Exit
}

// Set interface here:
BLENO_HCI_DEVICE_ID = 0;

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