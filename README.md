
# mason.github

> Template for an R package on GitHub, for [Mason](https://github.com/metacran/mason).

## Installation

This package needs Mason, so please go to
https://github.com/gaborcsardi/mason and install that first.
Then install this package with

```r
library(devtools)
install_github("gaborcsardi/mason.github")
```

## Usage

Call Mason from an empty directory:

```r
dir.create("mypackage")
setwd("mypackage")
mason::mason("github")
```

## License

MIT © [Gábor Csárdi](https://github.com/gaborcsardi)
