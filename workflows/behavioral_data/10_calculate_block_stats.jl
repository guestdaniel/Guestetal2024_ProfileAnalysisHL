using Pkg; Pkg.activate(Base.current_project());
using DataFramesMeta
using DataFrames
using CSV
using ProfileAnalysis
using Chain
using DataFrames
using DataFramesMeta

# Load data from disk
df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))

# Group all data by file index, extract tested increments, report
summary = @chain df begin
    groupby([:subj, :freq, :rove, :file_index])
    @combine(
        :inc_low = minimum(:increment),
        :inc_high = maximum(:increment),
        :range = maximum(:increment) - minimum(:increment),
    )
end

# Make quick summary plot
fig = Figure(; resolution=(1000, 1000))
ax = Axis(fig[1, 1])
for (idx, row) in enumerate(eachrow(summary))
    scatter!(ax, [row.inc_low, row.inc_high], [idx, idx]; color=:black)
    lines!(ax, [row.inc_low, row.inc_high], [idx, idx]; color=:black)
end
fig