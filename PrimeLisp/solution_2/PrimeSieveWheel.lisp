;;;; Common Lisp port of PrimeC/solution_2/sieve_5760of30030_only_write_read_bits.c by Daniel Spangberg
;;;
;;; run as:
;;;     sbcl --script PrimeSieveWheel.lisp
;;;


(declaim
  (optimize (speed 3) (safety 0) (debug 0)))


(defparameter *list-to* 100
  "list primes up to that number, set to nil to disable listing")


(defconstant +results+
  '((         10 . 4        )
    (        100 . 25       )
    (       1000 . 168      )
    (      10000 . 1229     )
    (     100000 . 9592     )
    (    1000000 . 78498    )
    (   10000000 . 664579   )
    (  100000000 . 5761455  )
    ( 1000000000 . 50847534 )
    (10000000000 . 455052511))
  "Historical data for validating our results - the number of primes
   to be found under some limit, such as 168 primes under 1000")


#+64-bit (defconstant +bits-per-word+ 64)
#-64-bit (defconstant +bits-per-word+ 32)

(defconstant +MASK+ (1- +bits-per-word+))
(defconstant +SHIFT+ (- (logcount +MASK+)))

(deftype nonneg-fixnum ()
  `(integer 0 ,most-positive-fixnum))

(deftype sieve-element-type ()
  `(unsigned-byte ,+bits-per-word+))


(defconstant +steps+ #(
 8 1 2 3 1 3 2 1 2 3 3 1 3 2 1 3 2 3 4 2 1 2 1 2 7 
 2 3 1 5 1 3 3 2 3 3 1 5 1 2 1 6 6 2 1 2 3 1 5 3 3 
 3 1 3 2 1 3 2 7 2 1 2 3 4 3 5 1 2 3 1 3 3 3 2 3 1 
 3 2 4 5 1 5 1 2 1 2 3 4 2 1 2 6 4 2 1 3 2 3 6 1 2 
 1 6 3 2 3 3 3 1 3 5 1 2 3 1 3 3 2 1 5 1 5 1 2 3 3 
 1 3 3 2 3 4 3 2 1 3 2 3 4 2 1 3 2 4 3 2 4 2 3 4 5 
 1 5 1 3 2 1 2 1 5 1 5 1 2 1 2 7 2 1 2 3 3 1 3 2 4 
 5 4 2 1 2 3 4 3 2 3 3 3 1 3 3 2 1 2 3 1 5 1 2 1 5 
 1 5 1 3 2 4 3 2 1 2 3 3 4 2 1 3 5 4 2 1 3 2 4 5 3 
 1 2 4 3 3 2 1 2 3 1 3 2 3 1 5 6 1 2 1 2 3 1 3 2 1 
 2 6 1 3 3 5 3 4 2 1 2 1 2 4 3 6 2 3 1 6 2 1 2 3 4 
 2 1 2 1 6 5 1 2 1 2 3 1 5 1 2 3 4 3 2 1 3 2 3 4 2 
 3 1 2 4 3 2 3 1 2 3 1 3 3 2 3 3 4 3 2 1 5 1 5 1 2 
 1 5 1 3 2 1 5 3 1 3 2 1 3 2 3 4 3 2 1 6 5 3 1 2 3 
 1 6 2 1 2 4 3 2 1 2 1 5 1 5 3 1 2 3 1 3 2 1 5 3 1 
 3 2 6 3 4 3 2 1 2 4 3 2 3 1 2 3 4 3 3 2 3 1 3 2 1 
 2 1 5 6 1 2 6 1 3 2 1 2 3 3 1 6 3 2 9 1 2 1 2 4 3 
 2 3 1 2 4 3 3 2 1 2 3 1 3 2 1 2 6 1 6 3 2 3 1 3 2 
 3 3 3 1 3 2 1 3 2 3 4 2 1 2 1 2 7 2 3 1 5 1 3 3 2 
 1 5 1 5 1 2 7 5 1 2 1 2 3 1 3 5 3 3 1 5 1 3 2 3 4 
 2 1 2 3 4 3 5 1 2 3 1 3 3 2 1 2 3 1 3 2 1 3 5 1 5 
 3 1 2 3 4 2 1 2 6 1 3 2 1 3 2 3 6 1 2 1 2 4 3 2 3 
 1 5 1 3 5 3 3 1 3 2 1 2 1 5 1 6 2 3 3 1 6 2 3 3 1 
 3 2 1 3 2 7 2 1 3 2 4 3 2 3 1 2 3 4 3 3 5 1 3 2 3 
 1 5 1 5 1 2 1 2 4 3 2 1 2 3 3 4 2 4 2 3 4 2 1 2 1 
 6 3 2 3 3 3 1 3 3 2 1 2 3 1 3 3 2 1 5 1 5 1 3 2 3 
 1 3 2 1 2 3 7 2 1 3 5 4 2 1 2 1 2 4 5 4 2 4 3 5 1 
 2 3 1 3 2 3 1 5 1 5 1 2 1 2 3 4 2 1 2 3 3 1 3 3 3 
 5 4 2 1 2 3 4 3 2 4 2 3 1 3 3 2 1 2 3 6 1 2 1 5 1 
 5 1 2 1 2 4 5 1 2 3 4 3 2 1 3 2 3 4 2 4 2 4 3 2 3 
 1 2 3 1 3 3 2 3 3 1 3 3 2 1 5 6 1 2 1 2 3 1 3 2 1 
 8 1 3 2 1 5 3 4 2 1 2 1 6 3 5 1 2 3 1 6 2 1 2 4 3 
 2 1 2 1 6 5 3 1 2 3 1 3 2 1 2 3 3 1 3 2 1 5 3 4 5 
 1 2 4 3 2 3 1 2 3 1 3 3 3 2 3 4 2 1 2 1 5 6 1 2 1 
 5 1 3 2 1 2 3 3 1 5 1 3 2 7 3 2 1 2 4 5 3 1 2 3 1 
 3 3 2 1 2 4 3 2 1 2 6 1 6 2 1 2 3 1 3 2 1 5 3 1 3 
 2 4 2 3 4 2 1 2 1 2 7 2 3 1 5 4 3 2 1 2 3 1 5 1 2 
 1 6 5 1 2 3 3 1 3 2 3 3 3 1 3 3 3 2 3 6 1 2 3 4 3 
 5 1 2 4 3 3 2 1 2 3 1 3 2 1 3 5 1 5 1 3 2 3 4 2 3 
 6 1 3 2 1 3 2 3 6 1 2 1 2 7 2 3 1 2 3 1 3 5 1 5 1 
 3 2 1 2 6 1 5 1 2 3 3 1 3 3 2 3 3 1 5 1 3 2 3 4 2 
 1 3 2 4 3 2 3 1 2 3 4 3 2 1 5 1 3 2 1 3 5 1 5 3 1 
 2 4 3 2 1 2 3 3 1 3 2 4 2 3 4 2 1 2 1 2 4 3 2 3 6 
 1 3 3 2 3 3 1 3 2 1 2 1 5 1 6 3 2 3 1 5 1 2 3 3 4 
 2 1 3 9 2 1 2 1 2 4 5 3 1 2 4 3 3 3 2 3 1 3 2 3 1 
 5 1 5 1 2 1 2 3 1 3 2 1 2 3 3 4 3 3 2 3 4 2 1 2 1 
 6 3 2 6 3 1 3 3 2 1 2 3 4 3 2 1 5 1 5 1 2 1 2 3 1 
 5 1 2 3 4 3 2 1 3 2 3 4 2 3 1 2 4 3 2 4 2 3 1 3 5 
 3 3 1 3 3 2 1 5 1 5 1 2 1 2 3 4 2 1 5 3 1 3 2 1 3 
 5 4 2 1 2 7 3 2 3 1 2 3 1 6 2 1 2 4 5 1 2 1 5 1 5 
 3 1 2 4 3 2 1 2 3 3 1 3 2 1 5 3 4 3 3 2 4 3 2 3 1 
 2 3 1 3 3 3 2 3 1 3 2 1 2 1 5 6 1 2 1 5 1 3 2 1 2 
 6 1 5 1 5 7 2 1 2 1 2 4 3 5 1 2 3 1 6 2 1 2 3 1 3 
 2 1 2 7 6 2 1 2 3 1 3 2 1 2 3 3 1 3 2 1 3 2 3 4 2 
 3 1 2 7 2 3 1 5 1 3 3 2 1 2 3 6 1 2 1 6 5 1 2 1 5 
 1 3 2 3 3 3 1 3 2 1 3 2 3 4 3 2 3 4 8 1 2 3 1 3 3 
 2 1 2 4 3 2 1 3 5 1 5 1 2 1 2 3 4 2 1 8 1 3 2 4 2 
 3 6 1 2 1 2 4 3 2 3 1 2 3 4 5 1 2 3 1 3 2 1 2 1 5 
 1 5 1 2 3 3 1 3 3 2 3 3 1 3 3 3 2 3 6 1 3 2 4 3 2 
 3 1 2 7 3 2 1 5 1 3 2 1 2 1 5 1 5 1 3 2 4 3 2 3 3 
 3 1 3 2 4 2 3 4 2 1 2 1 2 7 2 3 3 3 1 3 3 2 1 5 1 
 3 2 1 2 6 1 5 1 3 2 3 1 3 3 2 3 3 6 1 3 5 4 2 1 2 
 1 2 4 5 3 1 2 4 3 3 2 1 2 3 1 3 2 4 5 1 5 3 1 2 3 
 1 3 2 1 2 3 3 1 3 3 3 2 3 4 2 1 2 1 2 4 3 2 4 5 1 
 3 3 2 3 3 4 2 1 2 1 5 1 6 2 1 2 3 1 5 1 2 3 4 3 2 
 1 3 2 7 2 3 1 2 4 3 2 3 1 2 3 1 3 3 5 3 1 3 5 1 5 
 1 5 1 2 1 2 3 1 3 2 1 5 3 4 2 1 3 2 3 4 2 1 2 1 6 
 3 2 3 3 3 1 6 2 1 2 4 3 3 2 1 5 1 5 3 1 2 3 1 3 2 
 1 2 3 4 3 2 1 5 3 4 3 2 1 2 4 3 2 4 2 3 1 3 6 2 3 
 1 3 2 1 2 1 5 6 1 2 1 5 4 2 1 2 3 3 1 5 1 3 9 2 1 
 2 3 4 3 2 3 1 2 3 1 3 3 2 1 2 3 1 5 1 2 6 1 6 2 1 
 2 4 3 2 1 2 3 3 1 3 2 1 3 2 3 4 2 1 3 2 7 2 3 1 5 
 1 3 3 2 1 2 3 1 5 1 2 1 11 1 2 1 2 3 1 3 2 3 6 1 3 
 2 1 5 3 4 2 1 2 3 4 3 5 1 2 3 1 6 2 1 2 3 1 3 2 1 
 3 6 5 1 2 1 2 3 4 2 1 2 6 1 3 2 1 3 2 3 6 3 1 2 4 
 3 2 3 1 2 3 1 3 5 1 2 3 4 2 1 2 1 5 1 5 1 2 6 1 3 
 3 2 3 3 1 3 2 1 3 2 3 4 3 3 2 4 5 3 1 2 3 4 3 2 1 
 6 3 2 1 2 1 5 1 5 1 2 1 2 4 3 2 1 5 3 1 3 2 4 2 3 
 4 2 1 2 1 2 4 3 2 3 3 3 4 3 2 1 2 3 1 3 2 1 2 1 5 
 1 5 1 5 3 1 3 2 1 2 3 3 4 3 3 5 6 1 2 1 2 4 5 3 1 
 2 4 3 3 2 1 2 3 1 3 2 3 1 5 1 5 1 3 2 3 1 3 2 3 3 
 3 1 3 3 3 2 3 4 2 1 2 1 2 7 2 4 2 3 1 3 3 2 1 5 4 
 2 1 2 6 1 5 1 2 1 2 3 1 6 2 3 4 5 1 3 2 3 4 2 3 1 
 2 4 3 2 3 1 2 3 1 3 3 2 3 3 1 3 3 3 5 1 5 3 1 2 3 
 1 3 2 1 5 3 1 3 2 1 3 2 3 4 2 1 2 1 6 3 2 3 1 5 1 
 6 2 3 4 3 2 1 2 1 5 1 8 1 2 3 1 5 1 2 3 3 1 3 2 1 
 5 7 3 2 1 2 4 3 2 3 1 2 3 1 3 3 3 2 3 1 3 2 3 1 5 
 6 1 2 1 5 1 3 2 1 2 3 3 6 1 3 2 7 2 1 2 1 6 3 2 3 
 3 3 1 3 3 2 1 2 3 1 3 3 2 6 1 6 2 1 2 3 1 3 2 1 2 
 3 4 3 2 1 3 2 3 4 2 1 2 1 2 7 2 4 5 1 3 5 1 2 3 1 
 5 1 2 1 6 5 1 2 1 2 3 4 2 3 3 3 1 3 2 1 3 5 4 2 1 
 2 3 4 3 5 1 2 3 1 3 3 2 1 2 3 1 5 1 3 5 1 5 1 2 1 
 2 7 2 1 2 6 1 3 2 1 3 2 3 6 1 3 2 4 3 2 3 1 2 3 1 
 3 5 1 2 3 1 3 2 1 2 1 5 6 1 2 3 3 1 3 3 2 6 1 3 2 
 1 5 3 4 2 1 3 2 4 3 5 1 2 3 7 2 1 5 1 3 2 1 2 1 6 
 5 1 2 1 2 4 3 2 1 2 3 3 1 3 2 4 2 3 4 2 3 1 2 4 3 
 2 3 3 3 1 3 3 2 1 2 3 4 2 1 2 1 5 1 5 1 3 5 1 3 2 
 1 2 3 3 4 2 1 3 5 4 3 2 1 2 4 5 3 1 2 4 3 3 2 1 2 
 4 3 2 3 1 5 1 5 1 2 1 2 3 1 3 2 1 5 3 1 3 6 2 3 4 
 2 1 2 1 2 4 3 2 4 2 3 4 3 2 1 2 3 4 2 1 2 1 5 1 5 
 1 2 3 3 1 5 1 2 3 4 3 3 3 2 3 6 3 1 2 4 3 2 3 1 2 
 4 3 3 2 3 3 1 3 3 2 1 5 1 5 1 3 2 3 1 3 2 6 3 1 3 
 2 1 3 2 3 4 2 1 2 1 9 2 3 1 2 3 1 6 2 1 6 3 2 1 2 
 6 1 5 3 1 2 3 1 3 3 2 3 3 1 5 1 5 3 4 3 2 1 2 4 3 
 2 3 1 2 3 1 3 3 3 2 3 1 3 2 1 3 5 6 3 1 5 1 3 2 1 
 2 3 3 1 5 1 3 2 7 2 1 2 1 2 4 3 2 3 1 5 1 3 3 2 3 
 3 1 3 2 1 2 6 1 6 2 1 2 3 1 5 1 2 3 3 1 3 2 1 3 2 
 7 2 1 2 1 2 7 2 3 1 5 1 3 3 3 2 3 1 5 3 1 6 5 1 2 
 1 2 3 1 3 2 3 3 3 4 2 1 3 2 3 4 2 1 2 7 3 5 3 3 1 
 3 3 2 1 2 3 1 3 3 3 5 1 5 1 2 1 2 3 4 2 1 2 7 3 2 
 1 3 2 3 6 1 2 1 2 4 3 2 4 2 3 1 3 5 1 2 3 1 3 2 1 
 2 1 5 1 5 1 2 3 3 4 3 2 3 3 1 3 2 1 3 5 4 2 1 5 4 
 3 2 3 1 2 3 4 3 2 1 5 1 5 1 2 1 5 1 5 1 2 1 2 4 3 
 2 1 2 3 3 1 3 2 4 2 3 4 2 1 3 2 4 3 2 3 3 3 1 3 3 
 2 1 2 3 1 3 2 1 2 1 5 6 1 3 2 3 1 3 2 1 2 6 4 2 1 
 8 4 2 1 2 1 2 4 8 1 2 4 6 2 1 2 3 1 3 2 3 1 6 5 1 
 2 1 2 3 1 3 2 1 2 3 3 1 3 3 3 2 3 4 2 3 1 2 4 3 2 
 4 2 3 1 3 3 2 1 2 3 4 2 1 2 1 5 1 5 1 2 1 5 1 5 1 
 2 3 4 3 2 1 3 2 3 4 5 1 2 4 5 3 1 2 3 1 3 3 2 3 4 
 3 3 2 1 5 1 5 1 2 1 2 3 1 3 2 1 5 3 1 3 2 4 2 3 4 
 2 1 2 1 6 3 2 3 1 2 3 7 2 1 2 4 3 2 1 2 1 5 1 5 3 
 3 3 1 3 2 1 2 3 3 1 3 3 5 3 7 2 1 2 4 3 2 3 1 2 4 
 3 3 3 2 3 1 3 2 1 2 1 5 6 1 3 5 1 3 2 3 3 3 1 5 1 
 3 2 7 2 1 2 1 2 7 2 3 1 2 3 1 3 3 2 1 5 1 3 2 1 2 
 6 1 6 2 1 2 3 1 3 3 2 3 3 1 5 1 3 2 3 4 2 1 2 1 2 
 7 2 3 1 5 1 3 3 2 1 2 3 1 5 1 3 6 5 3 1 2 3 1 3 2 
 3 3 3 1 3 2 1 3 2 3 4 2 1 2 3 4 3 5 1 5 1 3 3 2 3 
 3 1 3 2 1 3 5 1 6 2 1 2 3 6 1 2 6 1 3 2 1 3 2 9 1 
 2 1 2 4 3 2 3 1 2 3 1 3 6 2 3 1 3 2 3 1 5 1 5 1 2 
 3 3 1 3 3 2 3 3 4 2 1 3 2 3 4 2 1 3 6 3 2 3 3 3 4 
 3 2 1 5 1 3 3 2 1 5 1 5 1 2 1 2 4 3 2 1 2 3 4 3 2 
 4 2 3 4 2 1 2 1 2 4 3 2 6 3 1 3 5 1 2 3 1 3 2 1 2 
 1 5 1 5 1 3 2 3 4 2 1 2 3 3 4 2 1 3 5 4 2 1 2 3 4 
 5 3 1 2 4 3 3 2 1 2 3 1 5 3 1 5 1 5 1 2 1 2 4 3 2 
 1 2 3 3 1 3 3 3 2 3 4 2 1 3 2 4 3 2 4 2 3 1 3 3 2 
 1 2 3 4 2 1 2 1 5 6 1 2 1 2 3 1 5 1 2 7 3 2 1 5 3 
 4 2 3 1 2 4 3 5 1 2 3 1 6 2 3 3 1 3 3 2 1 6 5 1 2 
 1 2 3 1 3 2 1 5 3 1 3 2 1 3 2 3 4 2 3 1 6 3 2 3 1 
 2 3 1 6 2 1 2 7 2 1 2 1 5 1 5 3 1 5 1 3 2 1 2 3 3 
 1 3 2 1 5 3 4 3 2 1 2 4 5 3 1 2 3 1 3 3 3 2 4 3 2 
 1 2 1 5 6 1 2 1 5 1 3 2 1 5 3 1 5 4 2 7 2 1 2 1 2 
 4 3 2 3 1 2 3 4 3 2 1 2 3 1 3 2 1 2 6 1 6 2 3 3 1 
 3 2 1 2 3 3 1 3 3 3 2 3 6 1 2 1 2 7 2 3 1 6 3 3 2 
 1 2 3 1 5 1 2 1 6 5 1 3 2 3 1 3 2 3 3 3 1 3 2 1 3 
 2 3 4 2 1 2 3 7 5 1 2 3 1 3 3 2 1 5 1 3 2 1 8 1 5 
 1 2 1 2 3 4 3 2 6 1 5 1 3 2 3 6 1 2 1 2 4 3 2 3 1 
 2 3 1 3 5 1 2 3 1 3 2 1 3 5 1 5 3 3 3 1 3 3 2 3 3 
 1 3 2 1 3 2 3 4 2 1 3 2 4 3 2 3 1 5 4 3 2 6 1 3 2 
 1 2 1 5 1 6 2 1 2 4 5 1 2 3 3 1 3 2 4 2 7 2 1 2 1 
 2 4 3 2 3 3 3 1 3 3 3 2 3 1 3 2 3 1 5 1 5 1 3 2 3 
 1 3 2 1 2 3 3 4 2 1 3 5 4 2 1 2 1 6 5 3 3 4 3 3 2 
 1 2 3 1 3 5 1 5 1 5 1 2 1 2 3 1 3 2 1 2 3 4 3 3 3 
 2 3 4 2 1 2 1 2 4 3 2 4 2 3 1 3 5 1 2 3 4 2 1 2 1 
 5 1 5 1 2 1 2 3 6 1 2 3 4 3 2 1 3 5 4 2 3 3 4 3 2 
 3 1 2 3 1 3 3 2 3 3 1 6 2 1 5 1 5 1 2 1 2 4 3 2 1 
 5 3 1 3 2 1 3 2 3 4 2 1 3 6 3 2 3 1 2 3 1 6 2 1 2 
 4 3 2 1 2 1 5 6 3 1 2 3 1 3 2 1 2 6 1 3 2 1 5 3 4 
 3 2 1 2 4 3 5 1 2 3 1 6 3 2 3 1 3 2 1 2 1 11 1 2 1 
 5 1 3 2 1 2 3 3 1 5 1 3 2 7 2 3 1 2 4 3 2 3 1 2 3 
 1 3 3 2 1 2 3 4 2 1 2 6 1 6 2 1 5 1 3 2 1 2 3 3 1 
 3 2 1 3 2 3 4 3 2 1 2 9 3 1 5 1 3 3 2 1 2 4 5 1 2 
 1 6 5 1 2 1 2 3 1 3 2 6 3 1 3 2 4 2 3 4 2 1 2 3 4 
 3 5 1 2 3 4 3 2 1 2 3 1 3 2 1 3 5 1 5 1 2 3 3 4 2 
 1 2 6 1 3 3 3 2 3 6 1 2 1 2 4 3 2 3 1 2 4 3 5 1 2 
 3 1 3 2 1 2 1 5 1 5 1 5 3 1 3 5 3 3 1 3 2 1 3 2 3 
 4 2 1 3 2 7 2 3 1 2 3 4 3 2 1 5 1 3 2 1 2 6 1 5 1 
 2 1 2 4 3 3 2 3 3 1 5 4 2 3 4 2 1 2 1 2 4 3 2 3 3 
 3 1 3 3 2 1 2 3 1 3 2 1 3 5 1 5 4 2 3 1 3 2 1 2 3 
 3 4 2 1 3 5 4 2 1 2 1 2 4 5 3 1 6 3 3 2 3 3 1 3 2 
 3 1 5 1 6 2 1 2 3 1 5 1 2 3 3 1 3 3 3 2 7 2 1 2 1 
 2 4 3 2 4 2 3 1 3 3 3 2 3 4 2 3 1 5 1 5 1 2 1 2 3 
 1 5 1 2 3 7 2 1 3 2 3 4 2 3 1 6 3 2 3 3 3 1 3 3 2 
 3 3 1 3 3 2 1 5 1 5 1 2 1 2 3 1 3 2 1 5 4 3 2 1 3 
 2 3 4 2 1 2 1 6 3 2 4 2 3 1 8 1 2 4 3 2 1 2 1 5 1 
 5 3 1 2 3 4 2 1 2 3 3 1 3 2 1 8 4 3 2 3 4 3 2 3 1 
 2 3 1 3 3 3 2 3 1 5 1 2 1 5 6 1 2 1 6 3 2 1 2 3 3 
 1 5 1 3 2 7 2 1 3 2 4 3 2 3 1 2 3 1 3 3 2 1 2 3 1 
 3 2 1 2 6 7 2 1 2 3 1 3 2 1 2 6 1 3 2 1 5 3 4 2 1 
 2 1 2 7 5 1 5 1 6 2 1 2 3 1 5 1 2 1 6 5 1 2 1 2 3 
 1 3 2 3 3 3 1 3 2 1 3 2 3 4 2 3 3 4 3 5 1 2 3 1 3 
 3 2 1 2 3 4 2 1 3 5 1 5 1 2 1 5 4 2 1 2 6 1 3 2 1 
 3 2 3 7 2 1 2 4 5 3 1 2 3 1 3 5 1 2 4 3 2 1 2 1 5 
 1 5 1 2 3 3 1 3 3 5 3 1 3 2 4 2 3 4 2 1 3 2 4 3 2 
 3 1 2 3 4 3 2 1 5 1 3 2 1 2 1 5 1 5 1 2 3 4 3 2 1 
 2 3 3 1 3 6 2 3 6 1 2 1 2 4 3 2 3 3 4 3 3 2 1 2 3 
 1 3 2 1 2 1 5 1 5 1 3 2 3 1 3 2 3 3 3 4 2 1 3 5 4 
 2 1 2 1 2 9 3 1 2 4 3 3 2 1 5 1 3 2 3 6 1 5 1 2 1 
 2 3 1 3 3 2 3 3 1 6 3 2 3 4 2 1 2 1 2 4 3 2 4 2 3 
 1 3 3 2 1 2 3 4 2 1 3 5 1 5 3 1 2 3 1 5 1 2 3 4 3 
 2 1 3 2 3 4 2 3 1 2 4 3 2 3 1 5 1 3 3 2 3 3 1 3 3 
 2 1 5 1 6 2 1 2 3 1 5 1 5 3 1 3 2 1 3 2 7 2 1 2 1 
 6 3 2 3 1 2 3 1 6 3 2 4 3 2 3 1 5 1 5 3 1 2 3 1 3 
 2 1 2 3 3 4 2 1 5 3 4 3 2 1 6 3 2 3 3 3 1 3 3 3 2 
 3 1 3 3 2 1 5 6 1 2 1 5 1 3 2 1 2 3 4 5 1 3 2 7 2 
 1 2 1 2 4 3 2 4 2 3 1 3 5 1 2 3 1 3 2 1 2 6 1 6 2 
 1 2 3 4 2 1 2 3 3 1 3 2 1 3 5 4 2 1 2 3 7 2 3 1 5 
 1 3 3 2 1 2 3 1 5 1 2 1 6 5 1 2 1 2 4 3 2 3 3 3 1 
 3 2 1 3 2 3 4 2 1 5 4 3 5 1 2 3 1 3 3 2 1 2 3 1 3 
 2 1 3 5 6 1 2 1 2 3 4 2 1 2 6 1 3 2 1 5 3 6 1 2 1 
 2 4 3 5 1 2 3 1 8 1 2 3 1 3 2 1 2 1 6 5 1 2 3 3 1 
 3 3 2 3 3 1 3 2 1 3 2 3 4 2 4 2 4 3 2 3 1 2 3 4 3 
 2 1 5 4 2 1 2 1 5 1 5 1 2 1 6 3 2 1 2 3 3 1 3 2 4 
 2 3 4 3 2 1 2 4 5 3 3 3 1 3 3 2 1 2 4 3 2 1 2 1 5 
 1 5 1 3 2 3 1 3 2 1 5 3 4 2 4 5 4 2 1 2 1 2 4 5 3 
 1 2 7 3 2 1 2 3 1 3 2 3 1 5 1 5 1 2 3 3 1 3 2 1 2 
 3 3 1 3 3 3 2 3 6 1 2 1 2 4 3 2 4 2 4 3 3 2 1 2 3 
 4 2 1 2 1 5 1 5 1 3 2 3 1 5 3 3 4 3 2 1 3 2 3 4 2 
 3 1 2 7 2 3 1 2 3 1 3 3 2 6 1 3 3 2 6 1 5 1 2 1 2 
 3 1 3 3 5 3 1 5 1 3 2 3 4 2 1 2 1 6 3 2 3 1 2 3 1 
 6 2 1 2 4 3 2 1 3 5 1 5 3 1 2 3 1 3 2 1 2 3 3 1 3 
 2 1 5 3 4 3 2 1 2 4 3 2 3 1 5 1 3 3 5 3 1 3 2 1 2 
 1 5 7 2 1 5 1 5 1 2 3 3 1 5 1 3 2 7 2 1 2 1 2 4 3 
 2 3 1 2 3 1 3 3 3 2 3 1 3 2 3 6 1 6 2 1 2 3 1 3 2 
 1 2 3 3 4 2 1 3 2 3 4 2 1 2 1 9 2 3 6 1 3 3 2 1 2 
 3 1 6 2 1 6 5 1 2 1 2 3 1 3 2 3 3 4 3 2 1 3 2 3 4 
 2 1 2 3 4 3 6 2 3 1 3 5 1 2 3 1 3 2 1 3 5 1 5 1 2 
 1 2 3 4 2 1 2 6 1 3 2 1 3 5 6 1 2 3 4 3 2 3 1 2 3 
 1 3 5 1 2 3 1 5 1 2 1 5 1 5 1 2 3 4 3 3 2 3 3 1 3 
 2 1 3 2 3 4 2 1 3 2 4 3 2 3 1 2 3 4 3 2 1 5 1 3 2 
 1 2 1 5 6 1 2 1 2 4 3 2 1 2 6 1 3 2 6 3 4 2 1 2 1 
 2 4 3 5 3 3 1 6 2 1 2 3 1 3 2 1 2 1 6 5 1 3 2 3 1 
 3 2 1 2 3 3 4 2 1 3 5 4 2 3 1 2 4 5 3 1 2 4 3 3 2 
 1 2 3 4 2 3 1 5 1 5 1 2 1 5 1 3 2 1 2 3 3 1 3 3 3 
 2 3 4 3 2 1 2 4 5 4 2 3 1 3 3 2 1 2 7 2 1 2 1 5 1 
 5 1 2 1 2 3 1 5 1 5 4 3 2 4 2 3 4 2 3 1 2 4 3 2 3 
 1 2 3 4 3 2 3 3 1 3 3 2 1 5 1 5 1 2 3 3 1 3 2 1 5 
 3 1 3 3 3 2 3 6 1 2 1 6 3 2 3 1 2 4 6 2 1 2 4 3 2 
 1 2 1 5 1 5 4 2 3 1 3 2 3 3 3 1 3 2 1 5 3 4 3 2 1 
 2 7 2 3 1 2 3 1 3 3 3 5 1 3 2 1 2 6 6 1 2 1 5 1 3 
 3 2 3 3 1 5 1 3 2 7 2 1 2 1 2 4 3 2 3 1 2 3 1 3 3 
 2 1 2 3 1 3 2 1 8 1
))


(defstruct sieve-state
  (maxints -1 :type fixnum :read-only t)
  (a nil :type simple-array :read-only t))


(defun create-sieve (maxints)
  (declare (fixnum maxints))
  (make-sieve-state
    :maxints maxints
    :a (make-array
         (1+ (floor (floor maxints +bits-per-word+) 2))
         :element-type 'sieve-element-type
         :initial-element 0)))


(defun run-sieve (sieve-state steps)
  (declare (sieve-state sieve-state) (simple-vector steps))

  (let* ((maxints (sieve-state-maxints sieve-state))
         (maxintsh (ash maxints -1))
         (a (sieve-state-a sieve-state))
         (q (1+ (isqrt maxints)))
         
         (factorh (ash 17 -1))
         (qh (ash q -1)))
    (declare (fixnum maxints maxintsh q factorh qh)
             (type (simple-array sieve-element-type 1) a))
    (do* ((step 1 (if (>= step 5759) 0 (1+ step)))
          (inc (aref steps step) (aref steps step)))
         ((> factorh qh))
      (declare (fixnum step inc))

      (when (zerop (logand (aref a (ash factorh +SHIFT+))
                           (ash 1 (logand factorh +MASK+))))

        (do* ((istep step (if (>= istep 5759) 0 (1+ istep)))
              (ninc (aref steps istep) (aref steps istep))
              (factor (1+ (ash factorh 1)))
              (i (ash (the fixnum (* factor factor)) -1)))
             ((>= i maxintsh))
          (declare (fixnum istep ninc factor i))

          (setf #1=(aref a (ash i +SHIFT+))
                (logior #1# (ash 1 (logand i +MASK+))))
          (incf i (the fixnum (* factor ninc)))))

      (incf factorh inc))))


(defun count-primes (sieve-state)
  (declare (sieve-state sieve-state))
  (let* ((maxints (sieve-state-maxints sieve-state))
         (a (sieve-state-a sieve-state))
         (ncount 6)
         (factor 17)
         (step 1)
         (inc (ash (aref +steps+ step) 1)))
    (declare (fixnum maxints ncount factor inc) (type (simple-array sieve-element-type 1) a))
    (when *list-to* (princ "2, 3, 5, 7, 11, 13, " *error-output*))
    (do () ((> factor maxints))
      (when (zerop (logand (aref a (ash factor (+ -1 +SHIFT+)))
                           (ash 1 (logand (ash factor -1) +MASK+))))
        (incf ncount)
        (when (and *list-to* (<= factor *list-to*))
          (format *error-output* "~d, " factor)))
      (incf factor inc)
      (setq step (if (>= step 5759) 0 (1+ step)))
      (setq inc (ash (the fixnum (aref +steps+ step)) 1)))
    (when *list-to*
      (when (< *list-to* (sieve-state-maxints sieve-state))
        (princ "..." *error-output*))
      (terpri *error-output*))
    ncount))


(defun validate (sieve-state)
  (let ((hist (cdr (assoc (sieve-state-maxints sieve-state) +results+ :test #'=))))
    (if (and hist (= (count-primes sieve-state) hist)) "yes" "no")))


(let* ((passes 0)
       (start (get-internal-real-time))
       (end (+ start (* internal-time-units-per-second 5)))
       result)
  (declare (fixnum passes))

  (do () ((>= (get-internal-real-time) end))
    (setq result (create-sieve 1000000))
    (run-sieve result +steps+)
    (incf passes))

  (let* ((duration  (/ (- (get-internal-real-time) start) internal-time-units-per-second))
         (avg (/ duration passes)))
    (format *error-output* "Algorithm: wheel  Passes: ~d  Time: ~f Avg: ~f ms Count: ~d  Valid: ~A~%"
            passes duration (* 1000 avg) (count-primes result) (let ((*list-to* nil)) (validate result)))

    (format t "mayerrobert-cl-wheel;~d;~f;1;algorithm=wheel,faithful=no,bits=1~%" passes duration)))
