import json
import os
from typing import List, Dict, Any
from langchain.schema import Document
from .chunkers.base import BaseChunker
from .chunkers.fixed_size import FixedSizeChunker
from .chunkers.semantic import SemanticChunker

class SlovakArticleProcessor:
    def __init__(self, chunker: BaseChunker = None):
        # Use provided chunker or default to fixed size
        if chunker is None:
            self.chunker = FixedSizeChunker()
        else:
            self.chunker = chunker
    
    def load_articles(self, articles_path: str) -> List[Dict[str, Any]]:
        """Load all JSON articles from the directory."""
        articles = []
        
        for filename in os.listdir(articles_path):
            if filename.endswith('.json'):
                file_path = os.path.join(articles_path, filename)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        article = json.load(f)
                        articles.append(article)
                except Exception as e:
                    print(f"Error loading {filename}: {e}")
                    continue
        
        print(f"Loaded {len(articles)} articles")
        return articles
    
    def process_articles(self, articles_path: str) -> List[Document]:
        """Process articles into LangChain documents with proper Slovak handling."""
        articles = self.load_articles(articles_path)
        documents = []
        
        print(f"\n📚 Processing {len(articles)} articles using {self.chunker.get_chunker_name()} chunking...")
        
        for idx, article in enumerate(articles, 1):
            # Extract content with proper Slovak encoding
            content = article.get('content', '')
            title = article.get('title', '')
            url = article.get('url', '')
            date = article.get('date', '')
            word_count = article.get('word_count', 0)
            
            if not content or len(content.strip()) < 100:
                print(f"  ⚠️  Skipping article {idx}/{len(articles)}: '{title}' (content too short)")
                continue
            
            # Show progress for every article (important for semantic chunking)
            print(f"\n📄 Article {idx}/{len(articles)}: {title[:60]}{'...' if len(title) > 60 else ''}")
            
            # Create the main document text
            full_text = f"Názov: {title}\n\n{content}"
            
            # Create metadata for this article
            metadata = {
                'title': title,
                'url': url,
                'date': date,
                'word_count': word_count,
                'source_file': article.get('source_file', ''),
                'language': 'sk'
            }
            
            # Use the chunker to create document chunks
            chunks = self.chunker.chunk_text(full_text, metadata)
            documents.extend(chunks)
            
            # Show summary for this article
            print(f"  ✅ Generated {len(chunks)} chunks from article {idx}/{len(articles)}")
            
            # Show overall progress every 10 articles for semantic chunking
            if self.chunker.get_chunker_name() == "Semantic" and idx % 10 == 0:
                print(f"\n📊 PROGRESS UPDATE: Completed {idx}/{len(articles)} articles, {len(documents)} total chunks so far")
        
        print(f"Created {len(documents)} document chunks from {len(articles)} articles using {self.chunker.get_chunker_name()} chunking")
        return documents
    
    def get_article_stats(self, articles_path: str) -> Dict[str, Any]:
        """Get statistics about the articles."""
        articles = self.load_articles(articles_path)
        
        total_articles = len(articles)
        total_words = sum(article.get('word_count', 0) for article in articles)
        
        # Get topics from titles (basic categorization)
        topics = {}
        for article in articles:
            title = article.get('title', '').lower()
            if 'epigenetika' in title:
                topics['epigenetika'] = topics.get('epigenetika', 0) + 1
            elif 'mitochondrie' in title or 'mitochondria' in title:
                topics['mitochondrie'] = topics.get('mitochondrie', 0) + 1
            elif 'hormóny' in title or 'hormny' in title:
                topics['hormóny'] = topics.get('hormóny', 0) + 1
            elif 'kvantov' in title:
                topics['kvantová biológia'] = topics.get('kvantová biológia', 0) + 1
            else:
                topics['ostatné'] = topics.get('ostatné', 0) + 1
        
        return {
            'total_articles': total_articles,
            'total_words': total_words,
            'average_words_per_article': total_words / total_articles if total_articles > 0 else 0,
            'topics': topics
        }