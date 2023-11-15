lib <- c('data.table','tidyverse','magrittr','parallel','psych','gridExtra','ggpubr','rstatix','ggrepel')
suppressMessages(lapply(lib, require, character.only = T));
image <- function(x, ratio){
    options(repr.plot.width = x, repr.plot.height = x*ratio)

}
matdim <- function(x, y){
    options(repr.matrix.max.rows = x, repr.matrix.max.cols = y)
}
