
class LREP::Message {
  has $.context is rw;
  has $.input is rw = "";
  has $.output is rw = "";
  method append($text) {
    $.output = $text;
  }
}

class LREP {

  use Linenoise;

  has $.context is rw;
  has $.composed is rw;

  # Ignore &handler
  sub echo_middleware(&handler) {
    -> $message {
      $message.append($message.input);
      $message;
    }
  }

  sub eval_middleware(&handler) {
    -> $message {
      if $message {
        my $eval_result = EVAL $message.input, context => $message.context;
        # TODO: Does the result here overwrite input? output? new thing?
        $message.input = $eval_result;
        my $result = &handler($message);
        $result;
      }
      CATCH {
        default {
          $message = LREP::Message.new(output => "REPL Exception: $_");
        }
      }
      $message;
    }
  }

  sub print_middleware(&handler) {
    -> $message {
      my $result = &handler($message);
      say $result.output;
      $result;
    }
  }

  # Ignores input and instead gets data from the user
  sub read_middleware(&handler) {
    -> $message {
      my $cmd = linenoise '> ';
      last if !$cmd.defined;
      $message.input = $cmd;
      my $result = &handler($message);
      $result;
    }
  }

  method add_middleware(*@middleware) {
    $.composed ||= -> $message { $message };
    for @middleware -> $mid {
      $.composed = $mid($.composed);
    }
  }

  method start {
    self.add_middleware(&echo_middleware);
    self.add_middleware(&eval_middleware);
    self.add_middleware(&read_middleware);
    self.add_middleware(&print_middleware);
    loop {
      my $blank_message = LREP::Message.new(context => $.context);
      &($.composed)($blank_message);
    }
  }

  our sub here {
    my $context = CALLER::;
    my $repl = LREP.new(context => $context);
    $repl.start;
  }

}

