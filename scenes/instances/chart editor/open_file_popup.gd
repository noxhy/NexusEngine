extends FileDialog


func _on_file_selected(path): self.queue_free()
func _on_close_requested(): self.queue_free()
