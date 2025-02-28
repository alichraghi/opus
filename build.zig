const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const cross_target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const target = cross_target.toTarget();

    const lib = b.addStaticLibrary(.{
        .name = "opus",
        .target = cross_target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.defineCMacro("USE_ALLOCA", null);
    lib.defineCMacro("OPUS_BUILD", null);
    lib.defineCMacro("HAVE_CONFIG_H", null);
    lib.addIncludePath(.{ .path = "." });
    lib.addIncludePath(.{ .path = "include" });
    lib.addIncludePath(.{ .path = "celt" });
    lib.addIncludePath(.{ .path = "silk" });
    lib.addIncludePath(.{ .path = "celt/arm" });
    lib.addIncludePath(.{ .path = "silk/float" });
    lib.addIncludePath(.{ .path = "silk/fixed" });

    lib.addCSourceFiles(sources, &.{});
    if (target.cpu.arch.isX86()) {
        const sse = target.cpu.features.isEnabled(@intFromEnum(std.Target.x86.Feature.sse));
        const sse2 = target.cpu.features.isEnabled(@intFromEnum(std.Target.x86.Feature.sse2));
        const sse4_1 = target.cpu.features.isEnabled(@intFromEnum(std.Target.x86.Feature.sse4_1));

        const config_header = b.addConfigHeader(.{ .style = .blank }, .{
            .OPUS_X86_MAY_HAVE_SSE = sse,
            .OPUS_X86_MAY_HAVE_SSE2 = sse2,
            .OPUS_X86_MAY_HAVE_SSE4_1 = sse4_1,
            .OPUS_X86_PRESUME_SSE = sse,
            .OPUS_X86_PRESUME_SSE2 = sse2,
            .OPUS_X86_PRESUME_SSE4_1 = sse4_1,
        });
        lib.addConfigHeader(config_header);

        lib.addCSourceFiles(celt_sources_x86 ++ silk_sources_x86, &.{});
        if (sse) lib.addCSourceFiles(celt_sources_sse, &.{});
        if (sse2) lib.addCSourceFiles(celt_sources_sse2, &.{});
        if (sse4_1) lib.addCSourceFiles(celt_sources_sse4_1, &.{});
    }

    if (target.cpu.arch.isAARCH64() or target.cpu.arch.isARM()) {
        const neon = target.cpu.features.isEnabled(@intFromEnum(std.Target.aarch64.Feature.neon)) or
            target.cpu.features.isEnabled(@intFromEnum(std.Target.arm.Feature.neon));

        const config_header = b.addConfigHeader(.{ .style = .blank }, .{
            .OPUS_ARM_MAY_HAVE_NEON_INTR = neon,
            .OPUS_ARM_PRESUME_NEON_INTR = neon,
        });
        lib.addConfigHeader(config_header);

        lib.addCSourceFiles(celt_sources_arm ++ silk_sources_arm, &.{});
        if (neon) lib.addCSourceFiles(celt_sources_arm_neon ++ silk_sources_arm_neon, &.{});
    }

    lib.installHeadersDirectory("include", "");
    b.installArtifact(lib);
}

const sources = &[_][]const u8{
    "src/analysis.c",
    "src/mapping_matrix.c",
    "src/mlp_data.c",
    "src/mlp.c",
    "src/opus_decoder.c",
    "src/opus_encoder.c",
    "src/opus_multistream_decoder.c",
    "src/opus_multistream_encoder.c",
    "src/opus_multistream.c",
    "src/opus_projection_decoder.c",
    "src/opus_projection_encoder.c",
    "src/opus.c",
    "src/repacketizer.c",

    "celt/bands.c",
    "celt/celt.c",
    "celt/celt_encoder.c",
    "celt/celt_decoder.c",
    "celt/cwrs.c",
    "celt/entcode.c",
    "celt/entdec.c",
    "celt/entenc.c",
    "celt/kiss_fft.c",
    "celt/laplace.c",
    "celt/mathops.c",
    "celt/mdct.c",
    "celt/modes.c",
    "celt/pitch.c",
    "celt/celt_lpc.c",
    "celt/quant_bands.c",
    "celt/rate.c",
    "celt/vq.c",

    "silk/CNG.c",
    "silk/code_signs.c",
    "silk/init_decoder.c",
    "silk/decode_core.c",
    "silk/decode_frame.c",
    "silk/decode_parameters.c",
    "silk/decode_indices.c",
    "silk/decode_pulses.c",
    "silk/decoder_set_fs.c",
    "silk/dec_API.c",
    "silk/enc_API.c",
    "silk/encode_indices.c",
    "silk/encode_pulses.c",
    "silk/gain_quant.c",
    "silk/interpolate.c",
    "silk/LP_variable_cutoff.c",
    "silk/NLSF_decode.c",
    "silk/NSQ.c",
    "silk/NSQ_del_dec.c",
    "silk/PLC.c",
    "silk/shell_coder.c",
    "silk/tables_gain.c",
    "silk/tables_LTP.c",
    "silk/tables_NLSF_CB_NB_MB.c",
    "silk/tables_NLSF_CB_WB.c",
    "silk/tables_other.c",
    "silk/tables_pitch_lag.c",
    "silk/tables_pulses_per_block.c",
    "silk/VAD.c",
    "silk/control_audio_bandwidth.c",
    "silk/quant_LTP_gains.c",
    "silk/VQ_WMat_EC.c",
    "silk/HP_variable_cutoff.c",
    "silk/NLSF_encode.c",
    "silk/NLSF_VQ.c",
    "silk/NLSF_unpack.c",
    "silk/NLSF_del_dec_quant.c",
    "silk/process_NLSFs.c",
    "silk/stereo_LR_to_MS.c",
    "silk/stereo_MS_to_LR.c",
    "silk/check_control_input.c",
    "silk/control_SNR.c",
    "silk/init_encoder.c",
    "silk/control_codec.c",
    "silk/A2NLSF.c",
    "silk/ana_filt_bank_1.c",
    "silk/biquad_alt.c",
    "silk/bwexpander_32.c",
    "silk/bwexpander.c",
    "silk/debug.c",
    "silk/decode_pitch.c",
    "silk/inner_prod_aligned.c",
    "silk/lin2log.c",
    "silk/log2lin.c",
    "silk/LPC_analysis_filter.c",
    "silk/LPC_inv_pred_gain.c",
    "silk/table_LSF_cos.c",
    "silk/NLSF2A.c",
    "silk/NLSF_stabilize.c",
    "silk/NLSF_VQ_weights_laroia.c",
    "silk/pitch_est_tables.c",
    "silk/resampler.c",
    "silk/resampler_down2_3.c",
    "silk/resampler_down2.c",
    "silk/resampler_private_AR2.c",
    "silk/resampler_private_down_FIR.c",
    "silk/resampler_private_IIR_FIR.c",
    "silk/resampler_private_up2_HQ.c",
    "silk/resampler_rom.c",
    "silk/sigm_Q15.c",
    "silk/sort.c",
    "silk/sum_sqr_shift.c",
    "silk/stereo_decode_pred.c",
    "silk/stereo_encode_pred.c",
    "silk/stereo_find_predictor.c",
    "silk/stereo_quant_pred.c",
    "silk/LPC_fit.c",
};

const celt_sources_x86 = &[_][]const u8{
    "celt/x86/x86_celt_map.c",
    "celt/x86/x86cpu.c",
};

const celt_sources_sse = &[_][]const u8{
    "celt/x86/pitch_sse.c",
};

const celt_sources_sse2 = &[_][]const u8{
    "celt/x86/pitch_sse2.c",
    "celt/x86/vq_sse2.c",
};

const celt_sources_sse4_1 = &[_][]const u8{
    "celt/x86/celt_lpc_sse4_1.c",
    "celt/x86/pitch_sse4_1.c",
};

const celt_sources_arm = &[_][]const u8{
    "celt/arm/arm_celt_map.c",
    "celt/arm/armcpu.c",
};

const celt_sources_arm_asm = &[_][]const u8{
    "celt/arm/celt_pitch_xcorr_arm.s",
};

const celt_sources_arm_neon = &[_][]const u8{
    "celt/arm/celt_neon_intr.c",
    "celt/arm/pitch_neon_intr.c",
};

const celt_sources_arm_ne10 = &[_][]const u8{
    "celt/arm/celt_fft_ne10.c",
    "celt/arm/celt_mdct_ne10.c",
};

const silk_sources_x86 = &[_][]const u8{
    "silk/x86/x86_silk_map.c",
};

const silk_sources_sse4_1 = &[_][]const u8{
    "silk/x86/NSQ_sse4_1.c",
    "silk/x86/NSQ_del_dec_sse4_1.c",
    "silk/x86/VAD_sse4_1.c",
    "silk/x86/VQ_WMat_EC_sse4_1.c",
};

const silk_sources_arm = &[_][]const u8{
    "silk/arm/arm_silk_map.c",
};

const silk_sources_arm_neon = &[_][]const u8{
    "silk/arm/biquad_alt_neon_intr.c",
    "silk/arm/LPC_inv_pred_gain_neon_intr.c",
    "silk/arm/NSQ_del_dec_neon_intr.c",
    "silk/arm/NSQ_neon.c",
};

const silk_sources_fixed = &[_][]const u8{
    "silk/fixed/LTP_analysis_filter_FIX.c",
    "silk/fixed/LTP_scale_ctrl_FIX.c",
    "silk/fixed/corrMatrix_FIX.c",
    "silk/fixed/encode_frame_FIX.c",
    "silk/fixed/find_LPC_FIX.c",
    "silk/fixed/find_LTP_FIX.c",
    "silk/fixed/find_pitch_lags_FIX.c",
    "silk/fixed/find_pred_coefs_FIX.c",
    "silk/fixed/noise_shape_analysis_FIX.c",
    "silk/fixed/process_gains_FIX.c",
    "silk/fixed/regularize_correlations_FIX.c",
    "silk/fixed/residual_energy16_FIX.c",
    "silk/fixed/residual_energy_FIX.c",
    "silk/fixed/warped_autocorrelation_FIX.c",
    "silk/fixed/apply_sine_window_FIX.c",
    "silk/fixed/autocorr_FIX.c",
    "silk/fixed/burg_modified_FIX.c",
    "silk/fixed/k2a_FIX.c",
    "silk/fixed/k2a_Q16_FIX.c",
    "silk/fixed/pitch_analysis_core_FIX.c",
    "silk/fixed/vector_ops_FIX.c",
    "silk/fixed/schur64_FIX.c",
    "silk/fixed/schur_FIX.c",
};

const silk_sources_fixed_sse4_1 = &[_][]const u8{
    "silk/fixed/x86/vector_ops_FIX_sse4_1.c",
    "silk/fixed/x86/burg_modified_FIX_sse4_1.c",
};

const silk_sources_fixed_arm_neon = &[_][]const u8{
    "silk/fixed/arm/warped_autocorrelation_FIX_neon_intr.c",
};

const silk_sources_float = &[_][]const u8{
    "silk/float/apply_sine_window_FLP.c",
    "silk/float/corrMatrix_FLP.c",
    "silk/float/encode_frame_FLP.c",
    "silk/float/find_LPC_FLP.c",
    "silk/float/find_LTP_FLP.c",
    "silk/float/find_pitch_lags_FLP.c",
    "silk/float/find_pred_coefs_FLP.c",
    "silk/float/LPC_analysis_filter_FLP.c",
    "silk/float/LTP_analysis_filter_FLP.c",
    "silk/float/LTP_scale_ctrl_FLP.c",
    "silk/float/noise_shape_analysis_FLP.c",
    "silk/float/process_gains_FLP.c",
    "silk/float/regularize_correlations_FLP.c",
    "silk/float/residual_energy_FLP.c",
    "silk/float/warped_autocorrelation_FLP.c",
    "silk/float/wrappers_FLP.c",
    "silk/float/autocorrelation_FLP.c",
    "silk/float/burg_modified_FLP.c",
    "silk/float/bwexpander_FLP.c",
    "silk/float/energy_FLP.c",
    "silk/float/inner_product_FLP.c",
    "silk/float/k2a_FLP.c",
    "silk/float/LPC_inv_pred_gain_FLP.c",
    "silk/float/pitch_analysis_core_FLP.c",
    "silk/float/scale_copy_vector_FLP.c",
    "silk/float/scale_vector_FLP.c",
    "silk/float/schur_FLP.c",
    "silk/float/sort_FLP.c",
};
