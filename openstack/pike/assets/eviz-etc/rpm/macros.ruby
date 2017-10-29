%ruby_libdir %{_datadir}/ruby
%ruby_libarchdir %{_libdir}/ruby

# This is the local lib/arch and should not be used for packaging.
%ruby_sitedir site_ruby
%ruby_sitelibdir %{_prefix}/local/share/ruby/%{ruby_sitedir}
%ruby_sitearchdir %{_prefix}/local/%{_lib}/ruby/%{ruby_sitedir}

# This is the general location for libs/archs compatible with all
# or most of the Ruby versions available in the Fedora repositories.
%ruby_vendordir vendor_ruby
%ruby_vendorlibdir %{ruby_libdir}/%{ruby_vendordir}
%ruby_vendorarchdir %{ruby_libarchdir}/%{ruby_vendordir}

# For ruby packages we want to filter out any provides caused by private
# libs in %%{ruby_vendorarchdir}/%%{ruby_sitearchdir}.
#
# Note that this must be invoked in the spec file, preferably as
# "%{?ruby_default_filter}", before any %description block.
%ruby_default_filter %{expand: \
%global __provides_exclude_from %{?__provides_exclude_from:%{__provides_exclude_from}|}^(%{ruby_vendorarchdir}|%{ruby_sitearchdir})/.*\\\\.so$ \
}
