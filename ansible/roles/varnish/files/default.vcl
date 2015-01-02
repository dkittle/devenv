
import std;
import cookie;
 
backend default {
    .host = "ip-10-178-170-41.ec2.internal";
    .port = "8080";
    .max_connections = 100;
}

backend www2 {
    .host = "ip-10-152-165-250.ec2.internal";
    .port = "8080";
    .max_connections = 100;
}
backend local {
    .host = "127.0.0.1";
    .port = "8080";
    .max_connections = 100;
}

sub vcl_recv {

  std.log("host: " + req.http.Host);
  std.log("x-forwarded address: " + req.http.x-forwarded-for);
  std.log("client.ip: " + client.ip);

  set req.http.foundregsplit = "false";

  # Strip port number for localhost entry
  set req.http.Host = regsub(req.http.Host, "^([-0-9a-zA-Z]+):(\d+)", "\1");

  # Set the appropriate backend for domain name
  if (req.http.Host == "localhost") { std.log("local"); set req.backend = local; }
  if (req.http.Host == "www2.clearfit.com") { std.log("www2"); set req.backend = www2; }
  if (req.http.Host == "www.clearfit.com") { std.log("www"); set req.backend = default; }

  # Parse the cookie
  cookie.parse(req.http.Cookie);

  # only set the cookie if the customer lands on the home page
  if (req.url == "/" || req.url == "") {
    # Process the request for the following domain names: localhost, www2.clearfit.com and www.clearfit.com
    if (req.http.Host == "localhost" || req.http.Host == "www2.clearfit.com" || req.http.Host == "www.clearfit.com" || req.http.Host == "clearfit.com") {

      # Cookie handling
      if (cookie.get("regsplit")) {
        set req.http.regsplit = cookie.get("regsplit");
        set req.http.foundregsplit = "true";
      }
      else {
        if (req.http.User-Agent ~ "(MSIE 9.0)") {
          set req.http.regsplit = "A";
        }
        else {
          if (std.random(0, 99) < 50) {
            set req.http.regsplit = "A";
          } else {
            set req.http.regsplit = "B";
          }
        } // put user in one of two groups
      } // set user's group (IE9 = A)

      # URL path handling
      if (req.url == "/" || req.url == "") {
        if (req.http.regsplit == "A") {
          set req.url = "/homepage";
        }
        else {
          set req.url = "/split-reg";
        }
      }
    }
    else {
      set req.http.foundregsplit = "true";
    }
  }
  else {
    if (cookie.get("regsplit")) {
      set req.http.regsplit = cookie.get("regsplit");
      set req.http.foundregsplit = "true";
    }
    else {
      set req.http.regsplit = "A";
    }
  }
}

sub vcl_deliver {
  if (req.http.foundregsplit == "false") {
    set resp.http.Set-Cookie = "regsplit=" + req.http.regsplit + "; expires=" + cookie.format_rfc1123(now, 90d) + "; Path=/; Domain=.clearfit.com";
  }
}

# Drop any cookies Wordpress tries to send back to the client.
sub vcl_fetch {

}
