const HINTS = [
    # -isms from other languages
    Suggestion(MethodError, :(AbstractString + AbstractString),
               m -> "To concatenate strings use the `*` operator not `+`, try `\"$(m.args[1])\" * \"$(m.args[2])\"`."),
    Docs(MethodError, :(AbstractString + AbstractString),
         ["manual/strings#man-concatenation"]),
    Note(MethodError, :(AbstractString + AbstractString),
         "If you're wondering why `*` is used over `+`, the short version is
         to respect that concatenation is non-commutative."),
    Suggestion(MethodError, :(AbstractChar + AbstractChar),
               m -> "To apply an offset to a character use an integer not a character, try `'$(m.args[1])' + $(Int(m.args[2]))`."),
    Suggestion(MethodError, :(AbstractChar + AbstractChar),
               m -> "To make a string from two characters use the `string` function, try `string('$(m.args[1])', '$(m.args[2])')`."),
    Suggestion(MethodError, :(Integer * AbstractString),
               m -> "To repeat a string use the `^` operator not `*`, try `\"$(m.args[2])\" ^ $(m.args[1])`."),
    Suggestion(MethodError, :(Integer * AbstractChar),
               m -> "To repeat a character use the `^` operator not `*`, try `'$(m.args[2])' ^ $(m.args[1])`."),
    Suggestion(MethodError, :(max(Array)),
               "Use `maximum` not `max` to find the maximum of an array."),
    Suggestion(MethodError, :(min(Array)),
               "Use `minimum` not `min` to find the maximum of an array."),
    # Initialisation mistakes
    Suggestion(MethodError, :(Int64(AbstractString)),
               m -> "To parse a string to an integer, use `parse(Int, \"$(m.args[1])\")`"),
    Suggestion(MethodError, :(Integer(AbstractString)),
               m -> "To parse a string to an integer, use `parse(Integer, \"$(m.args[1])\")`"),
    Suggestion(MethodError, :(Float64(AbstractString)),
               m -> "To parse a string to a float, use `parse(Float64, \"$(m.args[1])\")`"),
    Note(MethodError, :(Cmd(AbstractString)),
         "A string cannot be directly cast to a Cmd, it must be split into tokens, e.g. `Cmd([\"date\", \"-I\"])`."),
    Suggestion(MethodError, :(Array(Type, Integer)),
               m -> if m.args[2] == 0
                   "To create an empty array of $(m.args[1]), use `$(m.args[1])[]`."
               else
                   "To initialise an empty array use a type parameter and undef with `$(m.f){$(m.args[1])}(undef, $(m.args[2]))`" *
                   if applicable(zero, m.args[1]) " or `zeros($(m.args[1]), $(m.args[2]))`." else "." end
               end),
    Suggestion(MethodError, :(Array(Type, Integer, Integer)),
               m -> "To initialise an empty array use a type parameter and undef with `$(m.f){$(m.args[1])}(undef, $(m.args[2]), $(m.args[3]))`" *
                   if applicable(zero, m.args[1]) " or `zeros($(m.args[1]), $(m.args[2]), $(m.args[3]))`." else "." end),
    # Conversion
    Suggestion(MethodError, :(convert(Type{String}, Any)),
               "To create a string from another type, use the `string` function instead of `convert`."),
    Suggestion(MethodError, :(convert(Type{<:Number}, AbstractString)),
               m -> "To convert a numeric string to a Number use `parse` instead of `convert`, try `parse($(m.args[1]), \"$(m.args[2])\")`"),
    Suggestion(MethodError, m -> m.f == convert && length(m.args) > 1 && m.args[2] isa AbstractArray && !(m.args[1] <: AbstractArray),
               m -> "When changing the type of an array, an array type must be provided, such as " *
                   if m.args[2] isa Vector "`Vector{$(m.args[1])}`." else "`Array{$(m.args[1]), $(ndims(m.args[2]))}`." end),
    # LinearAlgebra
    Suggestion(MethodError, :(adjoint(Any)),
         "This operation is intended for linear algebra usage — for general data manipulation see `permutedims`, which is non-recursive."),
    Suggestion(MethodError, :(transpose(Any)),
         "This operation is intended for linear algebra usage — for general data manipulation see `permutedims`, which is non-recursive."),
    # Other (non-methdo) errors, these don't work ATM :(
    Suggestion(OverflowError, "Consider using a `BigInt` or `BigFloat`."),
    Docs(OverflowError, ["/manual/integers-and-floating-point-numbers#Arbitrary-Precision-Arithmetic"]),
    Suggestion(InexactError, e -> e.T <: Integer,
               e -> "To round a value, use `round($(e.func), $(e.val))`.")
]
