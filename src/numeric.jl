# ------------------- #
# Numeric model types #
# ------------------- #

immutable Options{TD<:Union{Void,AbstractDistribution}, TG<:Union{Void,AbstractGrid}}
    grid::TG
    distribution::TD
    other::Dict{Symbol,Any}  # TODO: shouldn't need. Just keeps stuff around
end

Options(;grid=nothing, distribution=nothing, other=Dict{Symbol,Any}()) =
    Options(grid, distribution, other)

function Options(sm::AbstractSymbolicModel, calib::ModelCalibration)
    # numericize options
    _options = eval_with(calib, deepcopy(sm.options))

    _opts = Dict{Symbol,Any}()
    other = Dict{Symbol,Any}()

    # now construct Options object
    for k in keys(_options)
        data = pop!(_options, k)
        if k == :grid
            _opts[:grid] = _build_grid(data)
        elseif k == :distribution
            _opts[:distribution] = _build_dist(data, calib)
        else
            other[k] = data
        end
    end

    Options(;_opts..., other=other)
end

# TODO: given that fields are exactly the same should we make just a single
#       NumericModel and distinguish between DTCSCC and DTMSCC via type params?
immutable NumericModel{ID,kind} <: ANM{ID,kind}
    symbolic::SymbolicModel{ID,kind}
    calibration::ModelCalibration
    options::Options
    model_type::Symbol
    name::UTF8String
    filename::UTF8String
    factories::Dict{Symbol,FunctionFactory}
end

typealias DTCSCCModel{ID} NumericModel{ID,:dtcscc}
typealias DTMSCCModel{ID} NumericModel{ID,:dtmscc}
typealias DynareModel{ID} NumericModel{ID,:dynare}

_numeric_mod_type{ID}(::ASM{ID,:dtcscc}) = DTCSCCModel{ID}
_numeric_mod_type{ID}(::ASM{ID,:dtmscc}) = DTMSCCModel{ID}
_numeric_mod_type{ID}(::ASM{ID,:dynare}) = DynareModel{ID}

Base.convert(::Type{SymbolicModel}, m::NumericModel) = m.symbolic

function NumericModel{ID,kind}(sm::SymbolicModel{ID,kind}; print_code::Bool=false)
    # compile all equations
    recipe = RECIPES[model_type(sm)]
    numeric_mod = _numeric_mod_type(sm)

    factories = Dict{Symbol,FunctionFactory}()

    # compile equations
    for func_nm in keys(sm.equations)
        # extract spec from recipe
        spec = recipe[:specs][func_nm]

        # get expressions from symbolic model
        exprs = sm.equations[func_nm]
        bang_func_nm = Symbol(string(func_nm), "!")

        if length(exprs) == 0
            msg = "Model did not specify functions of type $(func_nm)"
            code = quote
                function $(func_nm)(::$(numeric_mod), args...)
                    error($msg)
                end

                function $(bang_func_nm)(::$(numeric_mod), args...)
                    error($msg)
                end
            end
        else
            ff = FunctionFactory(sm, func_nm)
            code = make_method(ff)
            factories[func_nm] = ff
        end

        print_code && println(code)
        eval(Dolo, code)
    end

    # get numerical calibration and options
    calib = ModelCalibration(sm)
    options = Options(sm, calib)

    NumericModel(sm, calib, options, sm.model_type, sm.name, sm.filename,
                 factories)
end

# ------------- #
# Other methods #
# ------------- #

filename(m::AbstractModel) = m.filename
name(m::AbstractModel) = m.name