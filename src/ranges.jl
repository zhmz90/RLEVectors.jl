## Range operations
# Take two runends vectors (strictly increasing uints) and find the number of unique values for the disjoin operation
function disjoin_length(x::Vector, y::Vector)
  i = length(x)
  j = length(y)
  nrun = i + j
  @inbounds while i > 0 && j > 0
    if x[i] > y[j]
      i = i - 1
    elseif x[i] < y[j]
      j = j - 1
    else
      i = i - 1
      j = j - 1
      nrun = nrun - 1
    end
  end
  return(nrun)
end

"""
Takes runends from two RLEVectors, make one new runends breaking the pair into non-overlapping runs.
Basically, this is an optimized `sort!(unique([x,y])))`. This is useful when comparing two RLEVector
objects. The values corresponding to each disjoint run in `x` and `y` can then be compared directly.

## Returns
An integer vector, of a type that is the promotion of the eltypes of the runends of x and y.

## Examples
x = RLEVector([1,1,2,2,3,3])
y = RLEVector([1,1,1,2,3,4])
for (i,j) in disjoin(x,y)
  println(x[i] + y[j])
end
"""
function disjoin(x::Vector,  y::Vector)
    length(x) == 0 && return(y) # At least one value to work on
    length(y) == 0 && return(x) # At least one value to work on
    nrun = disjoin_length(x, y)
    i = length(x)
    j = length(y)
    runends = Array(promote_type(eltype(x), eltype(y)), nrun)
    @inbounds while true
        xi = x[i]
        yj = y[j]
        if xi > yj
            runends[nrun] = xi
            i = i - 1
        elseif xi < yj
            runends[nrun] = yj
            j = j - 1
        else
            runends[nrun] = xi
            i = i - 1
            j = j - 1
        end
        nrun = nrun - 1
        if i == 0
            for r in 1:j runends[r] = y[r] end
            break
        elseif j == 0
            for r in 1:i runends[r] = x[r] end
            break
        end
    end
    return(runends)
end

function disjoin(x::RLEVector, y::RLEVector)
    i = nrun(x)
    j = nrun(y)
    length(x) != length(y) && error("RLEVectors of unequal length.")
    runind = disjoin_length(x.runends, y.runends)
    xv = x.runvalues
    yv = y.runvalues
    xe = x.runends
    ye = y.runends
    runends = Array(promote_type(eltype(x), eltype(y)), runind)
    runvalues_x = Array(eltype(x), runind)
    runvalues_y = Array(eltype(x), runind)
    @inbounds while true
        if xe[i] > ye[j]
            runends[runind] = xe[i]
            runvalues_x[runind] = xv[i]
            runvalues_y[runind] = yv[j]
            i = i - 1
        elseif xe[i] < ye[j]
            runends[runind] = ye[j]
            runvalues_x[runind] = xv[i]
            runvalues_y[runind] = yv[j]
            j = j - 1
        else
            runends[runind] = xe[i]
            runvalues_x[runind] = xv[i]
            runvalues_y[runind] = yv[j]
            i = i - 1
            j = j - 1
        end
        runind = runind - 1
        if i == 0
            for r in 1:j
                runends[r] = ye[r]
                runvalues_x[r] = xv[i]
                runvalues_y[r] = yv[r]
            end
            break
        elseif j == 0
            for r in 1:i
                runends[r] = xe[r]
                runvalues_x[r] = xv[r]
                runvalues_y[r] = yv[j]
            end
            break
        end
    end
    return( (runends, runvalues_x, runvalues_y ) )
end
