#!/usr/bin/env ruby

require 'webrick'
require 'webrick/httpproxy'
require 'uri'
require "pathname"
require 'stringio'
require 'zlib'

bookmarklet_url = 'bookmarxy.js'
bookmarklet_file = 'bookmarklet.js'

insert_javascript = <<EOS
if(window.top==window.self){
	window.setTimeout(
		function(){
			var script_tag=document.createElement("script");
			script_tag.src="#{bookmarklet_url}?date="+(new Date()).getTime();
			script_tag.type="text/javascript";
			var heads=document.getElementsByTagName("head");
			var insert_point=heads.length>=1?heads[0]:document.body;
			insert_point.appendChild(script_tag);
		},
		1000
	);
}
EOS

handler = Proc.new() {|req,res|

  case res['content-encoding']
  when 'gzip':
    gzr = Zlib::GzipReader.new(StringIO.new(res.body))
    res.body = gzr.read
    gzr.close
    res.header.delete('content-encoding')
    res.header.delete("content-length")
  when 'deflate':
    res.body = Zlib::Inflate.inflate(res.body)
    res.header.delete('content-encoding')
    res.header.delete("content-length")
  end

  if res.body
    res.body.gsub!(%r=</head>=mi,'<script type="text/javascript">'+"\r\n#{insert_javascript}\r\n"+'</script></head>')
  end
  if req.request_uri != nil and req.request_uri.to_s =~ Regexp.new(Regexp.escape(bookmarklet_url+'?date=')+'\d+')
    if FileTest.file? bookmarklet_file
      res.body = File.open(bookmarklet_file).binmode.read
      res.status = 200
    end
  end
}

ps = WEBrick::HTTPProxyServer.new(
  :BindAddress => nil,
  :Port => 8118,
  :Logger => nil,
  :AccessLog => nil,
  :ProxyVia => false,
#  :ProxyURI => URI.parse('http://parent_proxy_url:parent_proxy_port/'),
  :ProxyContentHandler => handler
)

Signal.trap('INT') do
  ps.shutdown
end

ps.start
