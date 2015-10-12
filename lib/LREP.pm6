
class LREP::Request {
  has $.context is rw;
  has $.cmd is rw;
}

class LREP::Response {
  has $.output is rw = "";

  method append($text) {
    $.output ~= $text;
  }
}

class LREP {

  use Linenoise;

  my $context;
  has $.context is rw;
  has &.composed-handler is rw;

  # my $composed;
  has $.composed is rw;

  # Ignore &handler
  sub null_middleware(&handler) {
    # say "Building ident_middlware with [{&handler.perl}]";
    -> $input {
      LREP::Response.new(output => $input.cmd);
    }
  }

  sub eval_middleware(&handler) {
    # say "Building eval_middlware with [{&handler.perl}]";
    -> $input {
      my $result = LREP::Response.new;
      if $input {
        my $eval_result = EVAL $input, context => $context;
        $input.cmd = $eval_result;
        $result = &handler($result);
      }
      CATCH {
        default {
          $result = LREP::Response.new(output => "REPL Exception: $_");
        }
      }
      $result;
    }
  }

  sub print_middleware(&handler) {
    # say "Building print_middlware with [{&handler.perl}]";
    -> $input {
      my $result = &handler($input);
      say $result.output;
      $result;
    }
  }

  # Ignores input and instead gets data from the user
  sub read_middleware(&handler) {
    # say "Building read_middlware with [{&handler.perl}]";
    -> $input {
      my $cmd = linenoise '> ';
      last if !$cmd.defined;
      $input.cmd = $cmd;
      my $result = &handler($input);
      $result;
    }
  }

  method compose_middleware(*@middleware) {
    $.composed ||= -> $input { say "Input: [$input]"; $input };
    for @middleware -> $mid {
      # say "Mid: {$mid.perl}";
      $.composed = $mid($.composed);
      # say "Middleware: {$.composed.perl}";
    }
  }

  method start {
    self.compose_middleware(
      &null_middleware,
      &eval_middleware,
      &read_middleware,
      &print_middleware);
    # say "Middleware: {$.composed.perl}";
    loop {
      &($.composed)(LREP::Request.new);
    }
  }

  our sub here {
    $context = CALLER::;
    my $repl = LREP.new(context => $context);
    $repl.start;
  }

}

