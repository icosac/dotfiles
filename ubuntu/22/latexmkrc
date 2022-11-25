add_cus_dep('glo', 'gls', 0, 'run_makeglossaries');
add_cus_dep('acn', 'acr', 0, 'run_makeglossaries');

$out_dir = 'out';

sub run_makeglossaries {
  my ($base_name, $path) = fileparse( $_[0] ); #handle -outdir param by splitting path and file, ...
  pushd $path; # ... cd-ing into folder first, then running makeglossaries ...

  if ( $silent ) {
      system "makeglossaries -q '$base_name'"; #unix
  }
  else {
      system "makeglossaries '$base_name'"; #unix
  };

  popd; # ... and cd-ing back again
}

push @generated_exts, 'glo', 'gls', 'glg', 'glsdefs';
push @generated_exts, 'acn', 'acr', 'alg';
push @generated_exts, 'synctex.gz';
$clean_ext .= ' %R.ist %R.xdy %R.bbl';

#$pdflatex = 'lualatex -interaction=nonstopmode -synctex=1 -shell-escape';
$pdflatex = 'pdflatex -interaction=nonstopmode -synctex=1 -shell-escape %O %S';
$lualatex = 'lualatex -interaction=nonstopmode -synctex=1 -shell-escape %O %S';

#$pdf_mode = 4;
$pdf_mode = 1;

