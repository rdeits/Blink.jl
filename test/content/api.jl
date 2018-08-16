using Blink
using Compat.Test

@testset "content! Tests" begin
    w = Window(Blink.@d(:show => false)); sleep(5.0)
    body!(w, ""); sleep(1.0)  # body! is not synchronous.
    @test (@js w document.querySelector("body").innerHTML) == ""

    # Test reloading body and a selector element.
    html = """<div id="a">hi world</div><div id="b">bye</div>"""
    body!(w, html); sleep(1.0)
    @test (@js w document.getElementById("a").innerHTML) == "hi world"
    @test (@js w document.getElementById("b").innerHTML) == "bye"
    content!(w, "div", "hello world"); sleep(1.0)
    @test (@js w document.getElementById("a").innerHTML) == "hello world"
    # TODO(nhdaly): Is this right? Should content!(w,"div",...) change _all_ divs?
    @test (@js w document.getElementById("b").innerHTML) == "bye"

    # Test `fade` parameter and scripts:
    fadeTestHtml = """<script>var testJS = "test";</script><div id="d">hi world</div>"""
    @testset "Fade True" begin
        # Must create a new window to ensure javascript is reset.
        w = Window(Blink.@d(:show => false)); sleep(5.0)

        body!(w, fadeTestHtml; fade=true); sleep(1.0)
        @test (@js w testJS) == "test"
    end
    @testset "Fade False" begin
        # Must create a new window to ensure javascript is reset.
        w = Window(Blink.@d(:show => false)); sleep(5.0)

        body!(w, fadeTestHtml; fade=false); sleep(1.0)
        @test (@js w testJS) == "test"
    end
end
