using Test, TestExtras
using BlockTensorKit
using TensorKit
using TensorOperations
using Random

##
Vtr = (
    SumSpace(ℂ^2, ℂ^1),
    SumSpace(ℂ^1, ℂ^2, ℂ^1)',
    SumSpace(ℂ^2, ℂ^3),
    SumSpace(ℂ^2, ℂ^2, ℂ^2),
    SumSpace(ℂ^1, ℂ^2, ℂ^3)',
)
W = Vtr[1] ⊗ Vtr[2] ⊗ Vtr[3] ← Vtr[4] ⊗ Vtr[5]
@testset "tensorcopy" begin
    for T in (Float32, ComplexF32), Asparse in (false, true)
        A = Asparse ? randn(T, W) : sprand(T, W, 0.5)
        B = convert(TensorMap, A)
        @tensor C1[4, 5, 1, 3, 2] := A[1, 2, 3, 4, 5]
        @tensor C2[4, 5, 1, 3, 2] := B[1, 2, 3, 4, 5]
        @test convert(TensorMap, C1) ≈ C2
    end
end
##

@testset "tensoradd" begin
    for T in (Float32, ComplexF32), Asparse in (false, true), Bsparse in (false, true)
        A = !Asparse ? randn(T, W) : sprand(T, W, 0.5)
        B = !Bsparse ? randn(T, W) : sprand(T, W, 0.5)
        α = randn(T)
        @tensor C1[a, b, c, d, e] := A[a, b, c, d, e] + α * B[a, b, c, d, e]
        @tensor C2[a, b, c, d, e] :=
            convert(TensorMap, A)[a, b, c, d, e] + α * convert(TensorMap, B)[a, b, c, d, e]
        @test convert(TensorMap, C1) ≈ C2

        D = !Asparse ? randn(T, W) : sprand(T, W, 0.5)
        E = TensorOperations.tensoralloc_add(T, D, ((3, 2, 1, 5, 4), ()), true, Val(false))
        if Bsparse
            E = sparse(E)
        end
        E = Random.randn!(E)
        @tensor F1[a, b, c, d, e] := E[a, b, c, d, e] + α * conj(D[c, b, a, e, d])

        @tensor F2[a, b, c, d, e] :=
            convert(TensorMap, E)[a, b, c, d, e] +
            α * conj(convert(TensorMap, D)[c, b, a, e, d])
        @test convert(TensorMap, F1) ≈ F2
    end
end
##

@testset "tensortrace" begin
    for T in (Float32, ComplexF32)
        A = randn(T, W[1] ⊗ W[2] ← W[2] ⊗ W[3])
        B = convert(TensorMap, A)
        @tensor C1[a, b] := A[a, c, c, b]
        @tensor C2[a, b] := B[a, c, c, b]
        @test convert(TensorMap, C1) ≈ C2

        A2 = randn(T, W[1] ⊗ W[2] ⊗ W[3] ← W[1] ⊗ W[2] ⊗ W[4] ⊗ W[3])
        B2 = convert(TensorMap, A2)
        @tensor D1[e, a, d] := A2[a, b, c, d, b, e, c]
        @tensor D2[e, a, d] := B2[a, b, c, d, b, e, c]
        @test convert(TensorMap, D1) ≈ D2
    end
end

##

@testset "tensorcontract" begin
    for T in (Float64, ComplexF64), Asparse in (false, true), Bsparse in (false, true)
        WA = W[1] ⊗ W[2] ⊗ W[3] ← W[1] ⊗ W[4]
        WB = W[3]' ⊗ W[5] ← W[2] ⊗ W[1]
        A = Asparse ? sprand(T, WA, 0.5) : rand(T, WA)
        B = Bsparse ? sprand(T, WB, 0.5) : rand(T, WB)
        @tensor C1[a, g, e, d, f] := A[a, b, c, d, e] * B[c, f, b, g]
        @tensor C2[a, g, e, d, f] :=
            convert(TensorMap, A)[a, b, c, d, e] * convert(TensorMap, B)[c, f, b, g]
        @test convert(TensorMap, C1) ≈ C2

        D = if Asparse
            sprand(real(T), W[1] ⊗ W[1] ← W[1], 0.5)
        else
            randn(real(T), W[1] ⊗ W[1] ← W[1])
        end
        E = Bsparse ? sprand(T, W[1] ⊗ W[1] ← W[1], 0.5) : randn(T, W[1] ⊗ W[1] ← W[1])
        @tensor F1[a, b, c, d, e, f] := D[a, b, c] * conj(E[d, e, f])
        @tensor F2[a, b, c, d, e, f] :=
            convert(TensorMap, D)[a, b, c] * conj(convert(TensorMap, E)[d, e, f])
        @test convert(TensorMap, F1) ≈ F2
    end
end
