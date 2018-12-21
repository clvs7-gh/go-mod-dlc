## go.mod dependency license collector
### What is this?
Sometimes, I want NOTICE file including license text of used libraries on golang project.
But, collecting LICENSE/COPYING file manually is a little hard work.

This script collects LICENSE/COPYING file which attached with used library from your $GOPATH/pkg/mod directory.

### Limitation
Library/Project which not use go.mod is currently not supported.

### Disclaimer
**WARNING** : This script is created for my hobby code, **ABSOLUTELY NOT FOR PRODUCTION.**

If you use this script on any production environment and even it cause any harmful situation, I could not take any responsibility. Sorry :-(

### License
CC-0 (Public Domain).

