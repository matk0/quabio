import re
import numpy as np
from typing import List, Dict, Any
from langchain.schema import Document
from langchain_openai import OpenAIEmbeddings
from sklearn.metrics.pairwise import cosine_similarity
from .base import BaseChunker

class SemanticChunker(BaseChunker):
    """Semantic chunking strategy using sentence embeddings and similarity clustering."""
    
    def __init__(self, similarity_threshold: float = 0.75, max_chunk_size: int = 1000, min_chunk_size: int = 600):
        super().__init__()
        self.similarity_threshold = similarity_threshold
        self.max_chunk_size = max_chunk_size
        self.min_chunk_size = min_chunk_size
        
        # Initialize embeddings model
        self.embeddings = OpenAIEmbeddings(
            model="text-embedding-3-large",
            chunk_size=50  # Smaller batch size for sentence embeddings
        )
    
    def _split_into_sentences(self, text: str) -> List[str]:
        """Split text into sentences using basic punctuation rules for Slovak."""
        # Enhanced Slovak sentence splitting
        # Handle common abbreviations and special cases
        text = re.sub(r'\b(Dr|Prof|Mgr|Ing|PhD|RNDr|MUDr|MVDr|JUDr|PhDr|PaedDr|ThDr|etc|tzn|napr|resp|tzv|apod|č|s|r|o|z|v|k|na|po|pre|pri|cca|min|max|kg|g|mg|ml|l|cm|m|km|°C|%)\\.', r'\\1<DOT>', text)
        
        # Split on sentence endings
        sentences = re.split(r'[.!?]+(?=\s+[A-ZÁČĎÉÍĹĽŇÓŔŠŤÚÝŽ]|\s*$)', text)
        
        # Restore dots in abbreviations and clean up
        sentences = [re.sub(r'<DOT>', '.', sentence.strip()) for sentence in sentences if sentence.strip()]
        
        return sentences
    
    def _get_sentence_embeddings(self, sentences: List[str]) -> List[np.ndarray]:
        """Get embeddings for a list of sentences."""
        if not sentences:
            return []
        
        try:
            print(f"  📊 Generating embeddings for {len(sentences)} sentences...")
            # Get embeddings in batches to avoid rate limits
            embeddings = []
            batch_size = 20
            total_batches = (len(sentences) + batch_size - 1) // batch_size
            
            for i in range(0, len(sentences), batch_size):
                batch_num = i // batch_size + 1
                batch = sentences[i:i + batch_size]
                
                print(f"    🔄 Processing embedding batch {batch_num}/{total_batches} ({len(batch)} sentences)...")
                batch_embeddings = self.embeddings.embed_documents(batch)
                embeddings.extend([np.array(emb) for emb in batch_embeddings])
                
                # Show progress every few batches
                if batch_num % 5 == 0 or batch_num == total_batches:
                    print(f"    ✅ Completed {batch_num}/{total_batches} embedding batches")
            
            print(f"  ✅ Generated {len(embeddings)} sentence embeddings")
            return embeddings
        except Exception as e:
            print(f"  ❌ Error generating embeddings: {e}")
            return []
    
    def _group_sentences_by_similarity(self, sentences: List[str], embeddings: List[np.ndarray]) -> List[List[int]]:
        """Group consecutive sentences by semantic similarity."""
        if len(sentences) <= 1:
            return [[0]] if sentences else []
        
        print(f"  🔗 Grouping {len(sentences)} sentences by similarity (threshold: {self.similarity_threshold})...")
        
        groups = []
        current_group = [0]
        similarity_calculations = 0
        
        for i in range(1, len(sentences)):
            # Calculate similarity with the first sentence in current group
            first_idx = current_group[0]
            similarity = cosine_similarity(
                embeddings[first_idx].reshape(1, -1),
                embeddings[i].reshape(1, -1)
            )[0][0]
            similarity_calculations += 1
            
            # Show progress for longer texts
            if similarity_calculations % 50 == 0:
                print(f"    🔄 Processed {similarity_calculations} similarity calculations...")
            
            # If similar enough, add to current group
            if similarity >= self.similarity_threshold:
                current_group.append(i)
            else:
                # Start new group
                groups.append(current_group)
                current_group = [i]
        
        # Add the last group
        if current_group:
            groups.append(current_group)
        
        print(f"  ✅ Created {len(groups)} semantic groups from {len(sentences)} sentences")
        return groups
    
    def _create_chunks_from_groups(self, sentences: List[str], groups: List[List[int]]) -> List[str]:
        """Create text chunks from sentence groups, respecting size limits."""
        print(f"  📝 Creating chunks from {len(groups)} semantic groups...")
        chunks = []
        merged_count = 0
        split_count = 0
        
        for group_idx, group in enumerate(groups):
            # Show progress for many groups
            if len(groups) > 20 and (group_idx + 1) % 10 == 0:
                print(f"    🔄 Processing group {group_idx + 1}/{len(groups)}...")
            
            # Combine sentences in the group
            group_text = ' '.join(sentences[i] for i in group)
            
            # If the group is too large, split it further
            if len(group_text) > self.max_chunk_size:
                # Split large group into smaller chunks
                sub_chunks = self._split_large_group(sentences, group)
                chunks.extend(sub_chunks)
                split_count += 1
            elif len(group_text) < self.min_chunk_size and chunks:
                # If too small, try to merge with previous chunk
                if len(chunks[-1]) + len(group_text) <= self.max_chunk_size:
                    chunks[-1] = chunks[-1] + ' ' + group_text
                    merged_count += 1
                else:
                    chunks.append(group_text)
            else:
                chunks.append(group_text)
        
        print(f"  ✅ Created {len(chunks)} final chunks (merged: {merged_count}, split: {split_count})")
        return chunks
    
    def _split_large_group(self, sentences: List[str], group: List[int]) -> List[str]:
        """Split a large semantic group into smaller chunks."""
        chunks = []
        current_chunk = ""
        
        for idx in group:
            sentence = sentences[idx]
            
            # Check if adding this sentence would exceed max size
            if current_chunk and len(current_chunk) + len(sentence) > self.max_chunk_size:
                chunks.append(current_chunk.strip())
                current_chunk = sentence
            else:
                current_chunk = current_chunk + ' ' + sentence if current_chunk else sentence
        
        # Add the last chunk
        if current_chunk:
            chunks.append(current_chunk.strip())
        
        return chunks
    
    def chunk_text(self, text: str, metadata: Dict[str, Any]) -> List[Document]:
        """Chunk text using semantic similarity strategy."""
        article_title = metadata.get('title', 'Unknown Article')
        print(f"\n🧠 SEMANTIC CHUNKING: {article_title}")
        
        # Split into sentences
        print("  📄 Splitting text into sentences...")
        sentences = self._split_into_sentences(text)
        
        if not sentences:
            print("  ⚠️  No sentences found in text")
            return []
        
        print(f"  ✅ Found {len(sentences)} sentences")
        
        # Get embeddings for sentences
        embeddings = self._get_sentence_embeddings(sentences)
        
        if not embeddings:
            print("  ⚠️  Embedding generation failed, using fallback chunking...")
            # Fallback to simple sentence grouping if embeddings fail
            chunks = [' '.join(sentences[i:i+3]) for i in range(0, len(sentences), 3)]
        else:
            # Group sentences by semantic similarity
            groups = self._group_sentences_by_similarity(sentences, embeddings)
            # Create chunks from groups
            chunks = self._create_chunks_from_groups(sentences, groups)
        
        # Create Document objects
        print(f"  📦 Creating {len(chunks)} Document objects...")
        documents = []
        for i, chunk in enumerate(chunks):
            if not chunk.strip():
                continue
                
            # Create metadata for each chunk
            chunk_metadata = metadata.copy()
            chunk_metadata.update({
                'chunk_id': i,
                'total_chunks': len(chunks),
                'chunking_strategy': 'semantic',
                'similarity_threshold': self.similarity_threshold,
                'chunk_length': len(chunk)
            })
            
            # Create Document object
            doc = Document(
                page_content=chunk,
                metadata=chunk_metadata
            )
            documents.append(doc)
        
        self.chunk_count += len(documents)
        print(f"  ✅ COMPLETED: Generated {len(documents)} semantic chunks for '{article_title}'")
        return documents
    
    def get_chunker_name(self) -> str:
        return "Semantic"
    
    def get_chunker_description(self) -> str:
        return f"Semantic chunking with similarity threshold {self.similarity_threshold}"