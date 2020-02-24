//==--------------- kernel.cpp --- SYCL kernel -----------------------------==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include <CL/sycl/kernel.hpp>
#include <CL/sycl/program.hpp>
#include <detail/kernel_impl.hpp>

__SYCL_INLINE_NAMESPACE(cl) {
namespace sycl {

kernel::kernel(cl_kernel ClKernel, const context &SyclContext)
    : impl(std::make_shared<detail::kernel_impl>(
          detail::pi::cast<detail::RT::PiKernel>(ClKernel),
              detail::getSyclObjImpl(SyclContext))) {}

cl_kernel kernel::get() const { return impl->get(); }

bool kernel::is_host() const { return impl->is_host(); }

context kernel::get_context() const {
  return impl->get_info<info::kernel::context>();
}

program kernel::get_program() const {
  return impl->get_info<info::kernel::program>();
}

template <info::kernel param>
typename info::param_traits<info::kernel, param>::return_type
kernel::get_info() const {
  return impl->get_info<param>();
}

#define PARAM_TRAITS_SPEC(param_type, param, ret_type)                         \
  template ret_type kernel::get_info<info::param_type::param>() const;

#include <CL/sycl/info/kernel_traits.def>

#undef PARAM_TRAITS_SPEC

template <info::kernel_work_group param>
typename info::param_traits<info::kernel_work_group, param>::return_type
kernel::get_work_group_info(const device &dev) const {
  return impl->get_work_group_info<param>(dev);
}

#define PARAM_TRAITS_SPEC(param_type, param, ret_type)                         \
  template ret_type kernel::get_work_group_info<info::param_type::param>(      \
      const device &) const;

#include <CL/sycl/info/kernel_work_group_traits.def>

#undef PARAM_TRAITS_SPEC

template <info::kernel_sub_group param>
typename info::param_traits<info::kernel_sub_group, param>::return_type
kernel::get_sub_group_info(const device &dev) const {
  return impl->get_sub_group_info<param>(dev);
}

template <info::kernel_sub_group param>
typename info::param_traits<info::kernel_sub_group, param>::return_type
kernel::get_sub_group_info(
    const device &dev,
    typename info::param_traits<info::kernel_sub_group, param>::input_type val)
    const {
  return impl->get_sub_group_info<param>(dev, val);
}

#define PARAM_TRAITS_SPEC(param_type, param, ret_type)                         \
  template ret_type kernel::get_sub_group_info<info::param_type::param>(       \
      const device &) const;
#define PARAM_TRAITS_SPEC_WITH_INPUT(param_type, param, ret_type, in_type)     \
  template ret_type kernel::get_sub_group_info<info::param_type::param>(       \
      const device &, in_type) const;

#include <CL/sycl/info/kernel_sub_group_traits.def>

#undef PARAM_TRAITS_SPEC
#undef PARAM_TRAITS_SPEC_WITH_INPUT

kernel::kernel(std::shared_ptr<detail::kernel_impl> Impl) : impl(Impl) {}

} // namespace sycl
} // __SYCL_INLINE_NAMESPACE(cl)
