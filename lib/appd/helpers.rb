module Appd

  module Helpers
    # Print a message to the user.
    # Can use a block to display a message on the same line after the action is executed.
    #
    # @example
    #   display_ "General topic", :topic                              # => ">>  General topic "    
    #   display_ "Simple message", :message                           # => "    Simple message "
    #   display_ "live\n output\n", :live                             # => "    live "
    #                                                                 # => "    output "
    #   display_ "command executed !", :remote                        # => "    $ command executed ! "
    #   display_ "Please enter an username: " :ask                    # => "??  Please enter an username: "
    #   display_ "Error: The remote server is not reachable", :error  # => "!!  Error: The remote server is not reachable "
    #   display_ "executing an action", :message do
    #     # ...
    #     "done !"
    #   end                                                           # => "    executing an action (done !)"
    #
    # @note "display" is a reserved word in ruby, "display_" is used instead
    #   (http://ruby-doc.org/core-2.0/Object.html#method-i-display).
    # @param msg [String] the message to display, 
    # @param type [Symbol] the message type, can be :message, :topic, :remote, :ask or :error
    def display_(msg, type=:message, &block)
      msg.each_line do |line|
        case type
        when :message
          msg = "    #{line.chomp}"
        when :live
          msg = "    #{line}"
        when :topic
          msg = ">>  #{line.chomp} "
        when :remote
          msg = "    $  #{line.chomp} "
        when :ask
          msg = "??  #{line.chomp} "
        when :error
          msg = "!!  #{line.chomp} "
        end

        if block
          print msg
          status = block.call
          case status
          when TrueClass, FalseClass
            puts (status) ? " (success)" : " (failed)"
          when String
            puts " (#{status.chomp})"
          else
            puts " (done)"
          end
        else
          if type == :live
            print msg
          else
            puts msg
          end
        end
      end
    end
  end
end