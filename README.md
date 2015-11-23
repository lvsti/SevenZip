# SevenZip

SevenZip is an Objective-C wrapper framework around [p7zip](http://p7zip.sourceforge.net/), which in turn is a Unix port of [7zip](http://www.7-zip.org/). 

### Requirements

Xcode 6, OSX 10.9, iOS 8.4

(It probably builds on earlier platform versions as well but I didn't care enough to check.)

### Building

1. clone this repo
2. from the repo root, run

    ```
    $ scripts/setup.sh
    ```
    
3. open the Xcode project and build the `SevenZip` (OSX/iOS) target

If you just want to toy with it, take a look at the `SVZTest`/`SVZTestiOS` apps (separate targets).

### Big Fat Warning

At the moment, the wrapper is in very early stage of development but you can already read and create 7z archives from code without having to getting your feet wet with the underlying MFC/COM+/OLE/godknowswhat implementation. (I accept donations for funding my therapy to get over the shock of dealing with that code. With all due respect.)

Be warned that the code is experimental, has no tests, and is provided as-is. Be prepared for unwanted/undefined behavior, data losses, nazgul attacks etc.

### What it can already do

- listing the archive contents
- creating new archives with files/directories inside
- extracting all/some files from archives to file/memory

### What it can't do (yet)

- removing files from archives
- updating existing archives

Also coming soon: tests, automated builds, documentation, free candy/beer.

### Credits

- the p7zip developers for doing the lion's share of the porting
- Oleh Kulykov's [LzmaSDK-ObjC](https://github.com/OlehKulykov/LzmaSDK-ObjC) for some inspiration about implementing custom streams
- pixelglow's [ZipZap](https://github.com/pixelglow/ZipZap) for their API I shamelessly copied
