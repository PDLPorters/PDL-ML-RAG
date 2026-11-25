# PDL::ML::RAG

Retrieval-Augmented Generation (sliding-window document chunking, cosine-similarity vector store, prompt templating, and pluggable embedding/generation pipelines) for [PDL](https://pdl.perl.org/).

## Installation

```bash
cpanm .
```

Or via ExtUtils::MakeMaker:

```bash
perl Makefile.PL
make
make test
make install
```

## Quickstart

```perl
use strict;
use warnings;
use PDL;
use PDL::ML::RAG qw(chunk_text render_prompt normalize_vec);

my $rag = PDL::ML::RAG::Pipeline->new(
    embedder => sub {
        my ($text) = @_;
        my $lc = lc($text);
        return float([
            ($lc =~ /pdl|ndarray/ ? 1.0 : 0.0),
            ($lc =~ /faiss|knn/   ? 1.0 : 0.0),
        ]);
    },
    generator => sub {
        my ($prompt, $hits) = @_;
        return $hits->[0]->{text};
    },
    chunk_size => 120,
    overlap    => 20,
);

$rag->ingest([
    { text => 'PDL provides fast n-dimensional ndarray math.', metadata => { src => 'pdl' } },
    { text => 'FAISS accelerates kNN vector similarity search.', metadata => { src => 'faiss' } },
]);

my $res = $rag->query('How do I run kNN search?', k => 1);
print 'Answer: ', $res->{answer}, "\n";
```

## Documentation & Examples

- Runnable tutorial: `perl examples/quickstart.pl` (see [`examples/quickstart.pl`](examples/quickstart.pl))
- Full POD documentation: `perldoc PDL::ML::RAG` (or [`lib/PDL/ML/RAG.pm`](lib/PDL/ML/RAG.pm))

## License

Copyright 2026 Google LLC. Licensed under the the same terms as Perl itself.
