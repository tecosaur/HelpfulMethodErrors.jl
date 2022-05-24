module HelpfulErrors

using Markdown

include("hints.jl")
include("hintlist.jl")

function __init__()
    if isdefined(Base.Experimental, :register_error_hint)
        for errtype in unique(getproperty.(HINTS, :exception))
            Base.Experimental.register_error_hint(hintdispatch, errtype)
        end
    else
        println("\e[1;33m!\e[0;33m HelpfulErrors needs Base.Experimental.register_error_hint to work.")
    end
end

end
