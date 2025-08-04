from langchain.callbacks.base import BaseCallbackHandler
from langchain.schema import LLMResult
from typing import Any, Dict, List, Optional
import time
from datetime import datetime

class CostTrackingCallback(BaseCallbackHandler):
    """Callback handler to track OpenAI API token usage and costs."""
    
    def __init__(self):
        self.reset()
    
    def reset(self):
        """Reset tracking data for a new request."""
        self.start_time = None
        self.end_time = None
        self.token_usage = {}
        self.model_name = None
        self.error = None
    
    def on_llm_start(
        self, 
        serialized: Dict[str, Any], 
        prompts: List[str], 
        **kwargs: Any
    ) -> None:
        """Called when LLM starts running."""
        self.start_time = time.time()
        # Try multiple ways to get the model name from serialized data
        self.model_name = (
            serialized.get("model_name") or 
            serialized.get("model") or
            serialized.get("kwargs", {}).get("model") or
            kwargs.get("invocation_params", {}).get("model") or
            "gpt-4-turbo-preview"  # fallback to known model
        )
    
    def on_llm_end(self, response: LLMResult, **kwargs: Any) -> None:
        """Called when LLM ends successfully."""
        self.end_time = time.time()
        
        # Extract token usage from the response
        if response.llm_output and "token_usage" in response.llm_output:
            self.token_usage = response.llm_output["token_usage"]
            
        # If model name not set, try to get it from response
        if not self.model_name or self.model_name == "unknown":
            self.model_name = (
                response.llm_output.get("model_name") if response.llm_output else None
            ) or "gpt-4-turbo-preview"
    
    def on_llm_error(self, error: Exception, **kwargs: Any) -> None:
        """Called when LLM encounters an error."""
        self.end_time = time.time()
        self.error = str(error)
    
    def get_usage_data(self) -> Dict[str, Any]:
        """Get the tracked usage data."""
        response_time_ms = None
        if self.start_time and self.end_time:
            response_time_ms = int((self.end_time - self.start_time) * 1000)
        
        return {
            "model": self.model_name or "unknown",
            "prompt_tokens": self.token_usage.get("prompt_tokens", 0),
            "completion_tokens": self.token_usage.get("completion_tokens", 0),
            "total_tokens": self.token_usage.get("total_tokens", 0),
            "response_time_ms": response_time_ms,
            "request_timestamp": datetime.now(),
            "error": self.error
        }
    
    def has_usage_data(self) -> bool:
        """Check if we have token usage data."""
        return bool(self.token_usage.get("total_tokens", 0) > 0)