# latexmkrc

use File::Basename;
use Cwd qw(abs_path);

$out_dir = 'out';

# --- Engines ---------------------------------------------------------------
$pdflatex = 'pdflatex -interaction=nonstopmode -synctex=1 -shell-escape %O %S';
$lualatex = 'lualatex -interaction=nonstopmode -synctex=1 -shell-escape %O %S';

$pdf_mode = 1;

# $pdf_previewer = 'open -a Preview';

# --- Glossaries / Acronyms -------------------------------------------------
add_cus_dep('glo', 'gls', 0, 'makeglossaries');
add_cus_dep('acn', 'acr', 0, 'makeglossaries');

sub makeglossaries {
    my ($src) = @_;
    my ($base, $dir) = fileparse($src, qr/\.[^.]*/);

    my $wd = $dir;
    if (defined $out_dir && $out_dir ne '') {
        $wd = $dir ne '' ? $dir : "$out_dir/";
    }

    my $cmd = $silent
        ? "makeglossaries -q \"$base\""
        : "makeglossaries \"$base\"";

    my $old = Cwd::getcwd();
    chdir($wd) or die "latexmkrc: cannot chdir to '$wd': $!";
    my $ret = system($cmd);
    chdir($old);

    return ($ret == 0);
}

# --- Cleanup ---------------------------------------------------------------
push @generated_exts,
    qw(glo gls glg glsdefs acn acr alg synctex.gz);

$clean_ext .= ' %R.ist %R.xdy %R.bbl %R.bcf %R.run.xml';