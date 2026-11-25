# Copyright 2026 Google LLC
use strict;
use warnings;
use PDL;
use PDL::ML::RAG qw(chunk_text render_prompt normalize_vec);

# 1. Deterministic bag-of-keywords embedder returning a 1-D float PDL vector
my $embedder = sub {
    my ($text) = @_;
    my $lc = lc($text);
    return float([
        ($lc =~ /pdl|ndarray|matrix/ ? 1.0 : 0.0),
        ($lc =~ /faiss|vector|knn/   ? 1.0 : 0.0),
        ($lc =~ /rag|chunk|prompt/   ? 1.0 : 0.0),
    ]);
};

# 2. Generator callback (replace with PDL::Llama or an LLM API client)
my $generator = sub {
    my ($prompt, $hits) = @_;
    my $top = $hits->[0];
    return sprintf 'Based on [%s] (score=%.2f): %s',
        $top->{metadata}->{src}, $top->{score}, $top->{text};
};

# 3. Assemble the RAG pipeline and ingest documents
my $rag = PDL::ML::RAG::Pipeline->new(
    embedder   => $embedder,
    generator  => $generator,
    chunk_size => 120,
    overlap    => 20,
);

my $n_chunks = $rag->ingest([
    {
        text     => 'PDL provides fast n-dimensional ndarray math for Perl.',
        metadata => { src => 'pdl-docs' },
    },
    {
        text     => 'FAISS accelerates vector similarity and kNN search.',
        metadata => { src => 'faiss-docs' },
    },
    {
        text     => 'RAG combines document chunking, retrieval, and prompt templates.',
        metadata => { src => 'rag-docs' },
    },
]);
printf "Ingested %d chunks into store (%d total)\n", $n_chunks, $rag->store->count;

# 4. Query the pipeline
my $res = $rag->query('How do I run kNN vector search?', k => 2);
print 'Answer: ', $res->{answer}, "\n";
print 'Rendered prompt:', "\n", $res->{prompt}, "\n";
