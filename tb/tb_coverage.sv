
`timescale 1ns/1ps

module tb_coverage;

reg clock;
reg reset;
reg enable;
wire [3:0] count;

integer state_hits [0:15];
integer transition_hits [0:15][0:15];

integer i;
integer j;
integer covered_states;
integer covered_transitions;
integer total_state_hits;
integer total_transition_hits;

reg [3:0] previous_count;
reg previous_valid;

counter_4bit DUT(
    .clock(clock),
    .reset(reset),
    .enable(enable),
    .count(count)
);

initial
    clock = 0;

always
    #5 clock = ~clock;

initial
begin
    reset = 1;
    enable = 0;
    previous_count = 0;
    previous_valid = 0;
    covered_states = 0;
    covered_transitions = 0;

    for (i = 0; i < 16; i = i + 1)
    begin
        state_hits[i] = 0;

        for (j = 0; j < 16; j = j + 1)
            transition_hits[i][j] = 0;
    end

    $dumpfile("sim/coverage.vcd");
    $dumpvars(0, tb_coverage);

    repeat (2) @(negedge clock);
    reset = 0;

    for (i = 0; i < 40; i = i + 1)
    begin
        if (i % 5 == 0)
            enable = 0;
        else
            enable = 1;

        @(posedge clock);
        #1;

        if (state_hits[count] == 0)
            covered_states = covered_states + 1;

        state_hits[count] = state_hits[count] + 1;

        if (previous_valid && previous_count != count)
        begin
            if (transition_hits[previous_count][count] == 0)
                covered_transitions = covered_transitions + 1;

            transition_hits[previous_count][count] =
                transition_hits[previous_count][count] + 1;
        end

        previous_count = count;
        previous_valid = 1;

        $display(
            "TIME=%0t ENABLE=%b COUNT=%h COVERED_STATES=%0d COVERED_TRANSITIONS=%0d",
            $time, enable, count, covered_states, covered_transitions
        );

        @(negedge clock);
    end

    $display("\nSTATE COVERAGE REPORT");

    for (i = 0; i < 16; i = i + 1)
        $display("STATE %h : %0d hits", i, state_hits[i]);

    $display("\nTRANSITION COVERAGE REPORT");

    total_transition_hits = 0;

    for (i = 0; i < 16; i = i + 1)
    begin
        for (j = 0; j < 16; j = j + 1)
        begin
            if (transition_hits[i][j] > 0)
            begin
                $display(
                    "%h -> %h : %0d hits",
                    i, j, transition_hits[i][j]
                );

                total_transition_hits =
                    total_transition_hits + transition_hits[i][j];
            end
        end
    end

    total_state_hits = 0;

    for (i = 0; i < 16; i = i + 1)
        total_state_hits = total_state_hits + state_hits[i];

    $display("\nCOVERED STATES = %0d / 16", covered_states);
    $display("STATE COVERAGE = %0.2f%%", covered_states * 100.0 / 16);
    $display("DISTINCT TRANSITIONS COVERED = %0d", covered_transitions);
    $display("TOTAL STATE SAMPLES = %0d", total_state_hits);
    $display("TOTAL TRANSITION EVENTS = %0d", total_transition_hits);

    $display("\nCOVERAGE SIMULATION COMPLETED");
    $finish;
end

endmodule
