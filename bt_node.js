// Test script for btle messages

var bleno = require('./lib/noble');

// Set interface here:
BLENO_HCI_DEVICE_ID = 0;

if (bleno.state != 'poweredOn') {
    console.log('Attempting to bring up Bleno instance on' + myAddress);
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