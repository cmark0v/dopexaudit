# Dopex QA report

Dr. cmark0v

##

This is an itemized catalog of of concerning features incarnate in the codebase. 






The choice of ``DEFAULT_PRECISION=1e8`` is poor and also a misnomer. Thats the base used for oracle price data transmission, which is sensible, but it cant be mistaken for precision of any calculations you do with it on rational number with denominator in terms of it

