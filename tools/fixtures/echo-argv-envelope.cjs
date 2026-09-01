'use strict';
const args = process.argv.slice(2);
process.stdout.write(JSON.stringify({ count: args.length, args }));
