struct Hint{hinttype, M, E}
    exception::Type{<:Exception}
    matcher::E
    message::M
    priority::Int
end

Suggestion{M} = Hint{:suggestion, M}
Docs = Hint{:docs, Vector{String}}
Note{M} = Hint{:note, M}

const HINT_PRIORITIES = Dict(
    :suggestion => 1,
    :docs => 2,
    :note => 3)

Hint{hinttype, M}(exception::Type{<:Exception}, matcher::E, message::M, priority::Int=get(HINT_PRIORITIES, hinttype, 0)) where {hinttype, M, E}=
    Hint{hinttype, M, E}(exception, matcher, message, priority)

Hint{hinttype}(exception::Type{<:Exception}, matcher::E, message::M, priority::Int=get(HINT_PRIORITIES, hinttype, 0)) where {hinttype, M, E} =
    Hint{hinttype, M, E}(exception, matcher, message, priority)

Hint{hinttype, M}(exception::Type{<:Exception}, message::M, priority::Int=get(HINT_PRIORITIES, hinttype, 0)) where {hinttype, M}=
    Hint{hinttype, M, Bool}(exception, true, message, priority)

Hint{hinttype}(exception::Type{<:Exception}, message::M, priority::Int=get(HINT_PRIORITIES, hinttype, 0)) where {hinttype, M} =
    Hint{hinttype, M, Bool}(exception, true, message, priority)

# Display

const HINT_COLORS = Dict(
    :suggestion => :light_blue,
    :docs => :magenta,
    :note => :green)

function Base.show(io::IO, (hint, e)::Tuple{Hint, <:Exception})
    introduce(io, hint)
    showbody(io, hint, e)
end

function introduce(io::IO, ::Hint{T}) where {T}
    printstyled(io, uppercasefirst(string(T)), ": ",
                bold=true, color=get(HINT_COLORS, T, :default))
end

function showbody(io::IO, hint::Hint{T, <:AbstractString}, e::Exception) where {T}
    showbody(io, Hint{T}(hint.exception, hint.matcher, Markdown.parse(hint.message), hint.priority), e)
end

function showbody(io::IO, hint::Hint{T, Markdown.MD}, ::Exception) where {T}
    print(io, sprint(show, MIME("text/plain"), hint.message,
                     context=IOContext(io))[Markdown.margin+1:end])
end

function showbody(io::IO, hint::Hint{:docs, Vector{String}}, ::Exception) where {T}
    links = map(p -> termlink(string("https://docs.julialang.org/en/v", VERSION, '/', p), p),
                hint.message)
    print(io, "For more information see ",
          join(links, ", ", ", and"),
          '.')
end

function showbody(io::IO, hint::Hint{T, <:Function}, e::Exception) where {T}
    showbody(io, Hint{T}(hint.exception, hint.matcher, hint.message(e), hint.priority), e)
end

function termlink(uri, text)
    string("\e]8;;", uri, "\e\\\e[4m", text, "\e[0m\e]8;;\e\\")
end

function showhints(io::IO, hints::Vector{Hint}, exception::Exception)
    sort!(hints, by=h->h.priority)
    if length(hints) > 0
        print(io, "\n\n")
    end
    for hint in hints
        show(io, (hint, exception))
        print(io, '\n')
    end
end

# Dispatch

function hintdispatch(io::IO, exception::Exception)
    print(io, "\n(looking for hints...)")
    hintmatcher(h) =
        exception isa h.exception &&
        (h.matcher == true ||
        (h.matcher isa Function && h.matcher(exception)))
    applicablehints = filter(hintmatcher, HINTS)
    showhints(io, applicablehints, exception)
end

function hintdispatch(io::IO, exception::MethodError,
                      argtypes::Core.SimpleVector, kwargs::Union{Tuple{}, pairs(NamedTuple)})
    function hintmatcher(h::Hint{T, M, Expr}) where {T, M}
        h.exception == MethodError &&
            h.matcher.head == :call &&
            h.matcher.args[1] == nameof(exception.f) &&
            if length(h.matcher.args) > 1
                hkwargs = if h.matcher.args[2] isa Expr && h.matcher.args[2].head == :parameters
                    Dict(Tuple.(getfield.(h.matcher.args[2].args, :args)))
                end
                hargs = h.matcher.args[2+!isnothing(hkwargs):end]
                argmatch = length(argtypes) == length(hargs) &&
                    all(argtypes .<: eval.(hargs))
                kwargmatch = (isnothing(hkwargs) && isempty(kwargs)) ||
                    (keys(kwargs) == keys(hkwargs) &&
                    all(values(kwargs) .<: getfield.(hkwargs, keys(kwargs))))
                argmatch && kwargmatch
            else
                true
            end
    end
    function hintmatcher(h::Hint{T, M, <:Function}) where {T, M}
        h.exception == MethodError && h.matcher(exception)
    end
    hintmatcher(::Hint) = false
    applicablehints = filter(hintmatcher, HINTS)
    showhints(io, applicablehints, exception)
end
