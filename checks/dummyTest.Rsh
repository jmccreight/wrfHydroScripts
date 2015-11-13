args <- commandArgs(TRUE)

foo <- args[1]

cat(foo,'\n')

cat("i am doing just fine, thanks!\n")

q(status=1)