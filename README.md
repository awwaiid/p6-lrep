Fun little REPL for perl6.

Demo program:

    use LREP;

    sub hmm {
      my $x = "hello";
      LREP::here;
      say $x;
    }

    hmm;

Then when you run it you get a prompt. You can look at local vars and change them. "^D" to continue.

    > $x
    hello
    > $x = "bye"
    bye
    > ^D
    bye


