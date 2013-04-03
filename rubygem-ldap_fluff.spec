%global gem_name ldap_fluff
%if 0%{?rhel} == 6
%global gem_dir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gem_instdir %{gem_dir}/gems/%{gem_name}-%{version}
%global gem_docdir %{gem_dir}/doc/%{gem_name}-%{version}
%global gem_cache %{gem_dir}/cache/%{gem_name}-%{version}.gem
%global gem_spec %{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%global gem_libdir %{gem_instdir}/lib
%endif

Summary: LDAP integration for Active Directory, Free IPA and posix  
Name: rubygem-%{gem_name}
Version: 0.1.5
Release: 1%{?dist}
Group: Development/Languages
License: GPLv2+
URL: https://github.com/jsomara/ldap_fluff
Source0: http://rubygems.org/downloads/%{gem_name}-%{version}.gem
Requires: rubygems
Requires: rubygem(net-ldap)
BuildRequires: rubygems
BuildRequires: rubygem(rake)
BuildArch: noarch
Provides: rubygem(%{gem_name}) = %{version}
%if 0%{?rhel} == 6 || 0%{?fedora} < 17
Requires: ruby(abi) = 1.8
%else
Requires: ruby(abi) = 1.9.1
%endif
%if 0%{?fedora}
BuildRequires: rubygems-devel
%endif

%description
Provides multiple implementations of LDAP queries for various backends.

%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{name}

%prep
gem unpack %{SOURCE0}
%setup -q -D -T -n  %{gem_name}-%{version}
gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
mkdir -p .%{gem_dir}
gem build %{gem_name}.gemspec
#rake ldap_fluff:gem

gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem


%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}%{_sysconfdir}
cp -a ./%{_sysconfdir}/ldap_fluff.yml %{buildroot}%{_sysconfdir}/

rm -rf %{buildroot}%{gem_instdir}/{.yardoc,etc}

%files
%dir %{gem_instdir}
%{gem_libdir}
%exclude %{gem_cache}
%{gem_spec}
%config(noreplace) %{_sysconfdir}/ldap_fluff.yml

%files doc
%doc %{gem_docdir}
%{gem_instdir}/test

%changelog
* Wed Apr 03 2013 Jordan OMara <jomara@redhat.com> 0.1.5-1
- Adding test all task for travis (jomara@redhat.com)
- Fixing rakefile to use correct version from spec (jomara@redhat.com)
- Fixing rdoc task (jomara@redhat.com)

* Tue Apr 02 2013 Jordan OMara <jomara@redhat.com> 0.1.4-1
- More specific exception for config related errors (ares@igloonet.cz)
- Remove Ruby from .spec license field. (v.ondruch@tiscali.cz)
- thanks @msuchy for a MUCH better spec file (jomara@redhat.com)

* Thu Nov 01 2012 Miroslav Suchý <msuchy@redhat.com> 0.1.3-1
- update to ldap_fluff-0.1.3.gem and polish the spec (msuchy@redhat.com)

* Mon Jul 16 2012 Miroslav Suchý <msuchy@redhat.com> 0.1.1-2
- cleanup spec file (msuchy@redhat.com)

* Tue Jul 10 2012 Jordan OMara <jomara@redhat.com> 0.1.1-1
- new package built with tito

* Fri Jul 06 2012 Jordan OMara <jomara@redhat.com> 0.1.1-1
- A few minor IPA bugs (jomara@redhat.com)
- Adding .rvmrc; unit tests only support 1.9.3 (jomara@redhat.com)

* Fri Jul 06 2012 Jordan OMara <jomara@redhat.com> 0.1.0-1
- Adding the rest of free ipa support - testing, configuration
  (jomara@redhat.com)
- Adding FreeIPA support (jomara@redhat.com)
- Fix for empty set return for missing ldap user (jomara@redhat.com)
- Removing files that shouldnt have been committed (jomara@redhat.com)

* Fri Jun 29 2012 Jordan OMara <jomara@redhat.com> 0.0.6-1
- Adding some heavy recursive tests (jomara@redhat.com)
- Updating README to fix formatting (jsomara@gmail.com)
- Adding anon_queries to AD config; Fixing AD recursive group walk
  (jomara@redhat.com)
- Fixing a posix merge_filter bug. NEEDS SOME TESTS (jomara@redhat.com)
- Fixing a few minor bugs (jomara@redhat.com)

* Tue Jun 26 2012 Jordan OMara <jomara@redhat.com> 0.0.5-1
- Forgot to remove obsolete files from lib (jomara@redhat.com)

* Tue Jun 26 2012 Jordan OMara <jomara@redhat.com> 0.0.4-1
- rdoc/task -> rake/rdoctask for older rpm support (jomara@redhat.com)
- Updating readme (jomara@redhat.com)

* Tue Jun 26 2012 Jordan OMara <jomara@redhat.com> 0.0.3-1
- Automatic commit of package [rubygem-ldap_fluff] release [0.0.2-1].
  (jomara@redhat.com)

* Tue Jun 26 2012 Jordan OMara <jomara@redhat.com> 0.0.2-1
- new package built with tito

