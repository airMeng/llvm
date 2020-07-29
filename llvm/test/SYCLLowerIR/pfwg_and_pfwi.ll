; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -LowerWGScope -S | FileCheck %s

; Check that allocas which correspond to PFWI lambda object and a local copy of the PFWG lambda object
; are properly handled by LowerWGScope pass. Check that WG-shared local "shadow" variables are created
; and before each PFWI invocation leader WI stores its private copy of the variable into the shadow,
; then all WIs load the shadow value into their private copies ("materialize" the private copy).

%struct.bar = type { i8 }
%struct.zot = type { %struct.widget, %struct.widget, %struct.widget, %struct.foo }
%struct.widget = type { %struct.barney }
%struct.barney = type { [3 x i64] }
%struct.foo = type { %struct.barney }
%struct.foo.0 = type { i8 }

; CHECK: @[[GROUP_SHADOW_PTR:.*]] = internal unnamed_addr addrspace(3) global %struct.zot addrspace(4)*
; CHECK: @[[PFWG_SHADOW_PTR:.*]] = internal unnamed_addr addrspace(3) global %struct.bar addrspace(4)*
; CHECK: @[[PFWI_SHADOW:.*]] = internal unnamed_addr addrspace(3) global %struct.foo.0
; CHECK: @[[PFWG_SHADOW:.*]] = internal unnamed_addr addrspace(3) global %struct.bar
; CHECK: @[[GROUP_SHADOW:.*]] = internal unnamed_addr addrspace(3) global %struct.zot

define internal spir_func void @wibble(%struct.bar addrspace(4)* %arg, %struct.zot* byval(%struct.zot) align 8 %arg1) align 2 !work_group_scope !0 {
; CHECK-LABEL: @wibble(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[TMP:%.*]] = alloca [[STRUCT_BAR:%.*]] addrspace(4)*, align 8
; CHECK-NEXT:    [[TMP2:%.*]] = alloca [[STRUCT_FOO_0:%.*]], align 1
; CHECK-NEXT:    [[TMP0:%.*]] = load i64, i64 addrspace(1)* @__spirv_BuiltInLocalInvocationIndex
; CHECK-NEXT:    [[CMPZ3:%.*]] = icmp eq i64 [[TMP0]], 0
; CHECK-NEXT:    br i1 [[CMPZ3]], label [[LEADER:%.*]], label [[MERGE:%.*]]
; CHECK:       leader:
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast %struct.zot* [[ARG1:%.*]] to i8*
; CHECK-NEXT:    call void @llvm.memcpy.p3i8.p0i8.i64(i8 addrspace(3)* align 16 bitcast (%struct.zot addrspace(3)* @[[GROUP_SHADOW]] to i8 addrspace(3)*), i8* align 8 [[TMP1]], i64 96, i1 false)
; CHECK-NEXT:    [[ARG_CAST:%.*]] = bitcast [[STRUCT_BAR]] addrspace(4)* [[ARG:%.*]] to i8 addrspace(4)*
; CHECK-NEXT:    call void @llvm.memcpy.p3i8.p4i8.i64(i8 addrspace(3)* align 8 getelementptr inbounds (%struct.bar, [[STRUCT_BAR]] addrspace(3)* @[[PFWG_SHADOW]], i32 0, i32 0), i8 addrspace(4)* align 8 [[ARG_CAST]], i64 1, i1 false)
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    call void @_Z22__spirv_ControlBarrierjjj(i32 2, i32 2, i32 272) #0
; CHECK-NEXT:    [[TMP3:%.*]] = bitcast %struct.zot* [[ARG1]] to i8*
; CHECK-NEXT:    call void @llvm.memcpy.p0i8.p3i8.i64(i8* align 8 [[TMP3]], i8 addrspace(3)* align 16 bitcast (%struct.zot addrspace(3)* @[[GROUP_SHADOW]] to i8 addrspace(3)*), i64 96, i1 false)
; CHECK-NEXT:    [[TMP4:%.*]] = bitcast [[STRUCT_BAR]] addrspace(4)* [[ARG]] to i8 addrspace(4)*
; CHECK-NEXT:    call void @llvm.memcpy.p4i8.p3i8.i64(i8 addrspace(4)* align 8 [[TMP4]], i8 addrspace(3)* align 8 getelementptr inbounds (%struct.bar, [[STRUCT_BAR]] addrspace(3)* @[[PFWG_SHADOW]], i32 0, i32 0), i64 1, i1 false)
; CHECK-NEXT:    [[TMP5:%.*]] = load i64, i64 addrspace(1)* @__spirv_BuiltInLocalInvocationIndex
; CHECK-NEXT:    [[CMPZ:%.*]] = icmp eq i64 [[TMP5]], 0
; CHECK-NEXT:    br i1 [[CMPZ]], label [[WG_LEADER:%.*]], label [[WG_CF:%.*]]
; CHECK:       wg_leader:
; CHECK-NEXT:    store [[STRUCT_BAR]] addrspace(4)* [[ARG]], [[STRUCT_BAR]] addrspace(4)** [[TMP]], align 8
; CHECK-NEXT:    [[TMP3:%.*]] = load [[STRUCT_BAR]] addrspace(4)*, [[STRUCT_BAR]] addrspace(4)** [[TMP]], align 8
; CHECK-NEXT:    [[TMP4:%.*]] = addrspacecast %struct.zot* [[ARG1]] to [[STRUCT_ZOT:%.*]] addrspace(4)*
; CHECK-NEXT:    store [[STRUCT_ZOT]] addrspace(4)* [[TMP4]], [[STRUCT_ZOT]] addrspace(4)* addrspace(3)* @[[GROUP_SHADOW_PTR]]
; CHECK-NEXT:    br label [[WG_CF]]
; CHECK:       wg_cf:
; CHECK-NEXT:    [[TMP4:%.*]] = load i64, i64 addrspace(1)* @__spirv_BuiltInLocalInvocationIndex
; CHECK-NEXT:    [[CMPZ2:%.*]] = icmp eq i64 [[TMP4]], 0
; CHECK-NEXT:    br i1 [[CMPZ2]], label [[TESTMAT:%.*]], label [[LEADERMAT:%.*]]
; CHECK:       TestMat:
; CHECK-NEXT:    [[TMP5:%.*]] = bitcast %struct.foo.0* [[TMP2]] to i8*
; CHECK-NEXT:    call void @llvm.memcpy.p3i8.p0i8.i64(i8 addrspace(3)* align 8 getelementptr inbounds (%struct.foo.0, [[STRUCT_FOO_0]] addrspace(3)* @[[PFWI_SHADOW]], i32 0, i32 0), i8* align 1 [[TMP5]], i64 1, i1 false)
; CHECK-NEXT:    [[MAT_LD:%.*]] = load [[STRUCT_BAR]] addrspace(4)*, [[STRUCT_BAR]] addrspace(4)** [[TMP]]
; CHECK-NEXT:    store [[STRUCT_BAR]] addrspace(4)* [[MAT_LD]], [[STRUCT_BAR]] addrspace(4)* addrspace(3)* @[[PFWG_SHADOW_PTR]]
; CHECK-NEXT:    br label [[LEADERMAT]]
; CHECK:       LeaderMat:
; CHECK-NEXT:    call void @_Z22__spirv_ControlBarrierjjj(i32 2, i32 2, i32 272) #0
; CHECK-NEXT:    [[MAT_LD1:%.*]] = load [[STRUCT_BAR]] addrspace(4)*, [[STRUCT_BAR]] addrspace(4)* addrspace(3)* @[[PFWG_SHADOW_PTR]]
; CHECK-NEXT:    store [[STRUCT_BAR]] addrspace(4)* [[MAT_LD1]], [[STRUCT_BAR]] addrspace(4)** [[TMP]]
; CHECK-NEXT:    [[TMP6:%.*]] = bitcast %struct.foo.0* [[TMP2]] to i8*
; CHECK-NEXT:    call void @llvm.memcpy.p0i8.p3i8.i64(i8* align 1 [[TMP6]], i8 addrspace(3)* align 8 getelementptr inbounds (%struct.foo.0, [[STRUCT_FOO_0]] addrspace(3)* @[[PFWI_SHADOW]], i32 0, i32 0), i64 1, i1 false)
; CHECK-NEXT:    call void @_Z22__spirv_ControlBarrierjjj(i32 2, i32 2, i32 272) #0
; CHECK-NEXT:    [[WG_VAL_TMP4:%.*]] = load [[STRUCT_ZOT]] addrspace(4)*, [[STRUCT_ZOT]] addrspace(4)* addrspace(3)* @[[GROUP_SHADOW_PTR]]
; CHECK-NEXT:    call spir_func void @bar(%struct.zot addrspace(4)* [[WG_VAL_TMP4]], %struct.foo.0* byval(%struct.foo.0) align 1 [[TMP2]])
; CHECK-NEXT:    ret void
;
bb:
  %tmp = alloca %struct.bar addrspace(4)*, align 8
  %tmp2 = alloca %struct.foo.0, align 1
  store %struct.bar addrspace(4)* %arg, %struct.bar addrspace(4)** %tmp, align 8
  %tmp3 = load %struct.bar addrspace(4)*, %struct.bar addrspace(4)** %tmp, align 8
  %tmp4 = addrspacecast %struct.zot* %arg1 to %struct.zot addrspace(4)*
  call spir_func void @bar(%struct.zot addrspace(4)* %tmp4, %struct.foo.0* byval(%struct.foo.0) align 1 %tmp2)
  ret void
}

define internal spir_func void @bar(%struct.zot addrspace(4)* %arg, %struct.foo.0* byval(%struct.foo.0) align 1 %arg1) align 2 !work_item_scope !0 !parallel_for_work_item !0 {
bb:
  ret void
}

!0 = !{}
