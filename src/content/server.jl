# Resources

const resources = Dict{UTF8String, UTF8String}()

resource(f, name = basename(f)) = (@assert isfile(f); resources[name] = f)

resroute() =
  branch(req -> length(req[:path]) == 1 && haskey(resources, req[:path][1]),
         req -> @d(:body => open(readbytes, resources[req[:path][1]]),
                   :headers => Mux.fileheaders(req[:path][1])))

# Server setup

function page_handler(req)
  id = try parse(req[:params][:id]) catch e @goto fail end
  haskey(pool, id) || @goto fail
  active(pool[id].value) && @goto fail

  return readall(joinpath(dirname(@__FILE__), "main.html"))

  @label fail
  return @d(:body => "Not found",
            :status => 404)
end

function ws_handler(req)
  id = try parse(req[:params][:id]) catch e @goto fail end
  client = req[:socket]
  haskey(pool, id) || @goto fail
  p = pool[id].value
  active(p) && @goto fail

  p.sock = client
  @errs get(handlers(p), "init", identity)(p)
  while active(p)
    local data
    try
      data = read(client)
    catch e
      if isa(e, ErrorException) && contains(e.msg, "closed")
        handle_message(p, @d("type"=>"close"))
        break
      else
        rethrow()
      end
    end
    @errs handle_message(p, JSON.parse(ASCIIString(data)))
  end
  return

  @label fail
  close(client)
end

http_default =
  mux(Mux.defaults,
      resroute(),
      page(":id", page_handler),
      Mux.notfound())

ws_default =
  mux(Mux.wdefaults,
      page(":id", ws_handler),
      Mux.wclose)

function __init__()
  get(ENV, "BLINK_SERVE", "true") in ("1", "true") || return
  http = Mux.http_handler(Mux.App(http_default))
  delete!(http.events, "listen")
  ws = Mux.ws_handler(Mux.App(ws_default))
  serve(Mux.Server(http, ws), port)
end
