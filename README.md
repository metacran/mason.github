
# mason.rpkg

> A generic R package template for [Mason](https://github.com/gaborcsardi/mason).

## Installation

This package is basically useless without Mason, so please go to
https://github.com/gaborcsardi/mason first and install that first.
Then install this package with

```r
library(devtools)
install_github("gaborcsardi/mason.rpkg")
```

## Usage

Call Mason from an empty directory:

```r
dir.create("mypackage")
setwd("mypackage")
library(mason)
mason("rpkg")
```

## License

MIT © [Gábor Csárdi](https://github.com/gaborcsardi)
