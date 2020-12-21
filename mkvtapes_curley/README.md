# first draft of README

## Making Amanda Vtapes

Taken from http://charlescurley.com/blog/tag/amanda.html with kind permission of Charles Curley.

* mkvtapes.sh
* gettapedev.pl

You may want to customize the label parameter to amlabel to suit your labelstr (as defined in the appropriate amanda.conf).
You could hard code the path. But that gets problematic if you have multiple amanda configurations and multiple sets of vtapes,
or if you move your vtapes around. So a short perl program gets the vtape path from the relevant configuration, gettapedev.pl.
I wrote this function in Perl because I am lazy. The Amanda Perl modules have a tool for parsing an Amanda configuration file.
I just use that to pull the tape device out of the configuration file. That is the directory in which Amanda stores its virtual tapes.
As luck would have it, one of the examples in the POD was almost exactly what I needed.
The code depends on knowing where the Amanda Perl libraries are.
Adjust the use lib line for your installation and you should be set.
Note that we strip out the "file:" protocol specification. If you feed these scripts the name of a configuration 
that uses physical tapes, the results are undefined and probably not what you want.

