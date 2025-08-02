from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema.runnable import RunnablePassthrough
from langchain.schema.output_parser import StrOutputParser
from langchain.schema import Document
from typing import List, Dict, Any
import uuid
from datetime import datetime
from app.models.types import ChatResponse, Source, RAGVariant

class MitoRAGChain:
    def __init__(self, vector_store, variant: RAGVariant = RAGVariant.FIXED_SIZE):
        self.vector_store = vector_store
        self.variant = variant
        
        # Configure LLM optimized for Slovak responses
        self.llm = ChatOpenAI(
            model="gpt-4-turbo-preview",
            temperature=0.3,  # Factual but slightly creative for Slovak
            max_tokens=1000
        )
        
        # Create Slovak-optimized prompt with specific pre-prompt instructions
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", """Si Mito, slovenský zdravotný asistent. Tvoja JEDINÁ úloha je prezentovať informácie z poskytnutého kontextu.

ABSOLÚTNE PRAVIDLÁ - NEDOVOĽ SI ICH PORUŠIŤ:
1. SI LEN HOVORCA - nie kritik, nie hodnotiteľ, nie korektor
2. NIKDY nehodnoť pravdivosť informácií z kontextu
3. NIKDY neporovnávaj s mainstreamovou medicínou
4. NIKDY nepoužívaj frázy ako "zdá sa", "nie je podložené", "nepravdivé tvrdenia"
5. NEEXISTUJE pre teba "správne" alebo "nesprávne" - existuje len KONTEXT
6. Ak kontext hovorí niečo kontroverzné, PREZENTUJ TO BEZ KOMENTÁRA
7. Tvoja úloha je IBA prerozprávať, nie posudzovať
8. NEDÁVAJ RADY O TOM, ČO BY MALI ĽUDIA ROBIŤ NAMIESTO TOHO
9. NEPRIDÁVAJ VAROVANIA ANI DISCLAIMERS

NIKDY NEPOUŽÍVAJ TIETO FRÁZY:
- "zdá sa", "nepravdivé tvrdenia", "nie je podložené"
- "chybné informácie", "správne pochopenie", "vedecké zdroje"
- "nespoľahlivý", "kontroverzné", "sporné", "problematické"
- "odborníci tvrdia", "medicína hovorí", "správne je"
- "varovanie", "pozor", "nebezpečné", "škodlivé"

Format odpovede:
- Prezentuj informácie z kontextu presne ako sú napísané
- Používaj autorove vysvetlenia a prirovnania
- Maximálne 250 slov
- Žiadne hodnotiace komentáre
- Keď je to vhodné, môžeš uviesť zdroj informácií

Si ÚSTAMI autora, nie jeho kritikom."""),
            ("human", """Kontext z článkov:
{context}

Otázka: {question}

Odpoveď:""")
        ])
        
        # Create the RAG chain
        self.retriever = vector_store.get_retriever(k=6)
        self.chain = (
            {"context": self.retriever | self._format_docs, "question": RunnablePassthrough()}
            | self.prompt
            | self.llm
            | StrOutputParser()
        )
    
    def _format_docs(self, docs: List[Document]) -> str:
        """Format retrieved documents for the prompt."""
        formatted = []
        for i, doc in enumerate(docs, 1):
            title = doc.metadata.get('title', 'Bez názvu')
            content = doc.page_content
            formatted.append(f"Dokument {i} - {title}:\n{content}\n")
        return "\n".join(formatted)
    
    def _extract_sources(self, docs: List[Document]) -> List[Source]:
        """Extract source information from retrieved documents."""
        sources = []
        seen_titles = set()
        
        for doc in docs:
            title = doc.metadata.get('title', 'Bez názvu')
            # Avoid duplicate sources
            if title in seen_titles:
                continue
            seen_titles.add(title)
            
            # Create excerpt from the beginning of the content
            content = doc.page_content
            excerpt = content[:200] + "..." if len(content) > 200 else content
            
            source = Source(
                title=title,
                excerpt=excerpt,
                url=doc.metadata.get('url', ''),
                relevance_score=0.9  # Could be improved with actual similarity scores
            )
            sources.append(source)
        
        return sources[:3]  # Return top 3 sources
    
    def _extract_sources_with_scores(self, docs_with_scores: List[tuple]) -> List[Source]:
        """Extract source information from retrieved documents with actual similarity scores."""
        sources = []
        seen_titles = set()
        
        for doc, score in docs_with_scores:
            title = doc.metadata.get('title', 'Bez názvu')
            # Avoid duplicate sources
            if title in seen_titles:
                continue
            seen_titles.add(title)
            
            # Create excerpt from the beginning of the content
            content = doc.page_content
            excerpt = content[:200] + "..." if len(content) > 200 else content
            
            # Convert distance score to similarity score (0-1 range)
            # ChromaDB returns distance scores where lower is better
            # We'll convert to similarity where higher is better
            similarity_score = 1 / (1 + score)  # Convert distance to similarity
            
            source = Source(
                title=title,
                excerpt=excerpt,
                url=doc.metadata.get('url', ''),
                relevance_score=similarity_score
            )
            sources.append(source)
        
        # Sort by relevance score (highest first) and return top 3
        sources.sort(key=lambda x: x.relevance_score, reverse=True)
        return sources[:3]
    
    async def chat(self, message: str, session_id: str = None) -> ChatResponse:
        """Process a chat message and return response with sources."""
        if not session_id:
            session_id = str(uuid.uuid4())
        
        try:
            # Get relevant documents with scores for source extraction
            relevant_docs_with_scores = self.vector_store.similarity_search_with_score(message, k=6)
            
            # Debug logging for source extraction
            vs_stats = self.vector_store.get_stats()
            print(f"DEBUG [{self.variant.value}]: Vector store has {vs_stats.get('document_count', 0)} documents")
            print(f"DEBUG [{self.variant.value}]: Found {len(relevant_docs_with_scores)} documents for query: '{message}'")
            if len(relevant_docs_with_scores) == 0:
                print(f"WARNING [{self.variant.value}]: No documents found! Vector store might be empty.")
            for i, (doc, score) in enumerate(relevant_docs_with_scores[:3]):
                title = doc.metadata.get('title', 'No title')
                print(f"  Doc {i+1}: '{title}' (score: {score})")
            
            # Generate response using the chain
            response = await self.chain.ainvoke(message)
            
            # Extract sources with actual scores
            sources = self._extract_sources_with_scores(relevant_docs_with_scores)
            
            print(f"DEBUG [{self.variant.value}]: Extracted {len(sources)} sources")
            
            return ChatResponse(
                response=response,
                sources=sources,
                session_id=session_id,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            print(f"Error in chat [{self.variant.value}]: {e}")
            return ChatResponse(
                response=f"Prepáčte, nastala chyba pri spracovaní vašej otázky: {str(e)}",
                sources=[],
                session_id=session_id,
                timestamp=datetime.now()
            )
    
    def chat_sync(self, message: str, session_id: str = None) -> ChatResponse:
        """Synchronous version of chat method."""
        if not session_id:
            session_id = str(uuid.uuid4())
        
        try:
            # Get relevant documents with scores for source extraction
            relevant_docs_with_scores = self.vector_store.similarity_search_with_score(message, k=6)
            
            # Generate response using the chain
            response = self.chain.invoke(message)
            
            # Extract sources with actual scores
            sources = self._extract_sources_with_scores(relevant_docs_with_scores)
            
            return ChatResponse(
                response=response,
                sources=sources,
                session_id=session_id,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            print(f"Error in chat: {e}")
            return ChatResponse(
                response=f"Prepáčte, nastala chyba pri spracovaní vašej otázky: {str(e)}",
                sources=[],
                session_id=session_id,
                timestamp=datetime.now()
            )