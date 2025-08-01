import json
import os
from typing import List, Dict, Any
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document

class SlovakArticleProcessor:
    def __init__(self):
        # Optimized for Slovak text processing
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=800,  # Smaller chunks for better Slovak context preservation
            chunk_overlap=200,
            separators=["\n\n", "\n", ". ", "! ", "? ", " ", ""],
            keep_separator=True
        )
    
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
        
        for article in articles:
            # Extract content with proper Slovak encoding
            content = article.get('content', '')
            title = article.get('title', '')
            url = article.get('url', '')
            date = article.get('date', '')
            word_count = article.get('word_count', 0)
            
            if not content or len(content.strip()) < 100:
                continue
            
            # Create the main document text
            full_text = f"Názov: {title}\n\n{content}"
            
            # Split the content into chunks
            chunks = self.text_splitter.split_text(full_text)
            
            for i, chunk in enumerate(chunks):
                # Create metadata for each chunk
                metadata = {
                    'title': title,
                    'url': url,
                    'date': date,
                    'word_count': word_count,
                    'chunk_id': i,
                    'total_chunks': len(chunks),
                    'source_file': article.get('source_file', ''),
                    'language': 'sk'
                }
                
                # Create Document object
                doc = Document(
                    page_content=chunk,
                    metadata=metadata
                )
                documents.append(doc)
        
        print(f"Created {len(documents)} document chunks from {len(articles)} articles")
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