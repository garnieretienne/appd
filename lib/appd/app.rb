module Appd

	class App

		# User used to run the devops commands
    APPD_USER = "appd"

		attr_accessor :node, :name

		def initialize(options={})
			raise ArgumentError, "No node address provided" if !options[:node]
      options.each{|option, value| self.send("#{option}=", value)}
			@api = Appd::Client.new ssh_uri
		end

    # Build a SSH URI (ssh://`APPD_USER`@hostname:port)
		def ssh_uri
			"#{APPD_USER}@#{@node}"
		end
	end
end