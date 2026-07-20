Generate SystemVerilog Assertions that hold for the RTL below exactly as
written. Do not assume any intended or reference behavior beyond what the
code itself implements.

<rtl>
{rtl}
</rtl>

For each module, output a comment with the module name followed by its
assertions, in exactly this format:

<output_format>
// module_name
assert property (property_specification);
assert property (property_specification);

// next_module_name
assert property (property_specification);
</output_format>

Do not include module declarations or instantiate any modules. Output
nothing outside this format.
