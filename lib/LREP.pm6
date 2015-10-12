
class LREP {

  use Linenoise;

  my $context;
  has $.context is rw;
  has &.composed-handler is rw;

  # my $composed;
  has $.composed is rw;

  # Ignore &handler
  sub ident_middleware(&handler) {
    # say "Building ident_middlware with [{&handler.perl}]";
    -> $input {
      $input;
    }
  }

  sub eval_middleware(&handler) {
    # say "Building eval_middlware with [{&handler.perl}]";
    -> $input {
      my $result = "";
      if $input {
        $result = EVAL $input, context => $context;
        $result = &handler($result);
      }
      CATCH {
        default {
          $result = "REPL Exception: $_"
        }
      }
      $result;
    }
  }

  sub print_middleware(&handler) {
    # say "Building print_middlware with [{&handler.perl}]";
    -> $input {
      my $result = &handler($input);
      say $result;
      $result;
    }
  }

  # Ignores input and instead gets data from the user
  sub read_middleware(&handler) {
    # say "Building read_middlware with [{&handler.perl}]";
    -> $input {
      my $cmd = linenoise '> ';
      last if !$cmd.defined;
      my $result = &handler($cmd);
      $result;
    }
  }

  method compose_middleware(*@middleware) {
    # &.composed-handler ||= -> $input { say "Input: [$input]"; $input };
    # for @middleware -> $mid {
    #   say "Mid: {$mid.perl}";
    #   &.composed-handler = $mid(&.composed-handler);
    # say "Middleware: {&.composed-handler.perl}";
    # }
    $.composed ||= -> $input { $input };
    for @middleware -> $mid {
      # say "Mid: {$mid.perl}";
      $.composed = $mid($.composed);
      # say "Middleware: {$.composed.perl}";
    }
  }

  method start {
    self.compose_middleware(
      &ident_middleware,
      &eval_middleware,
      &read_middleware,
      &print_middleware);
    # say "Middleware: {&.composed-handler.perl}";
    # say "Middleware: {$.composed.perl}";
    # my $repl =
    #   self.print_middleware(
    #     self.read_middleware(
    #       self.eval_middleware(
    #         self.ident_middleware(-> $input {})
    #       )
    #     )
    #   );
    loop {
      # $repl("");
      # &.composed-handler("");
      &($.composed)("");
    }
  }

  our sub here {
    $context = CALLER::;
    my $repl = LREP.new(context => $context);
    $repl.start;
  }

}

