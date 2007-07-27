### General

class BagelDrop < Liquid::Drop

  def initialize(obj)
    @obj = obj
  end

end

class BagelSobjectDrop < BagelDrop

  def id             ; @obj.id                           ; end
  def relations_from ; @obj.sobject.relations_as_from    ; end
  def relations_to   ; @obj.sobject.relations_as_to      ; end
  def related_from   ; @obj.sobject.from                 ; end
  def related_to     ; @obj.sobject.to                   ; end
  def created_on     ; @obj.created_on                   ; end
  def updated_on     ; @obj.updated_on                   ; end
  def websites       ; @obj.sitems.map { |s| s.website } ; end
  def intro_or_body  ; @obj.intro_or_body                ; end
  def id_url         ; @obj.id_url                       ; end
  def published_by   ; @obj.published_by                 ; end

end

class DataDrop < Liquid::Drop

  def initialize(assigns)
    @assigns = assigns
  end

  def before_method(method)
    # Get object
    obj = @assigns[method.to_s]

    # Extract content
    obj.respond_to?(:call) ? obj.call : obj
  end

  def []=(key, value)
    @assigns[key] = value
  end

end

### Specific

class ContainerDrop < BagelSobjectDrop
  def title             ; @obj.title                ; end
  def description       ; @obj.description          ; end
end

class ContentTypeDrop < BagelDrop
  def title             ; @obj.title                ; end
end

class EventDrop < BagelSobjectDrop
  def title             ; @obj.title                ; end
  def intro             ; @obj.intro                ; end
  def body              ; @obj.body                 ; end
  def event_start       ; @obj.event_start          ; end
  def event_stop        ; @obj.event_stop           ; end
end

class FormDefinitionDrop < BagelDrop
  def title             ; @obj.name                 ; end
end

class FormDrop < BagelSobjectDrop

  def before_method(method)
    @obj.send(method.to_sym)
  end

end

class MediaItemDrop < BagelSobjectDrop
  def file_size         ; @obj.file_size            ; end
  def mime_type         ; @obj.mime_type            ; end
  def title             ; @obj.title                ; end
  def description       ; @obj.description          ; end
  def type              ; @obj[:type]               ; end
  def size              ; @obj.size                 ; end
  def filename          ; @obj.filename             ; end
  def width             ; @obj.width                ; end
  def height            ; @obj.height               ; end
  def thumbnail         ; @obj.thumbnail            ; end
  def parent            ; @obj.parent               ; end
  def thumbnails
    MediaItem.find(:all, :conditions => [ 'parent_id = ?', @obj.id ])
  end
end

class MenuDrop < BagelSobjectDrop
  def title             ; @obj.name                 ; end
  def parent            ; @obj.parent               ; end
end

class NewsDrop < BagelSobjectDrop
  def title             ; @obj.title                ; end
  def intro             ; @obj.intro                ; end
  def body              ; @obj.body                 ; end
end

class RelationDrop < BagelDrop
  def title             ; @obj.name                 ; end
  def content_type      ; @obj.content_type         ; end
end

class RelationshipDrop < BagelDrop
  def to                ; @obj.to_sobject.content   ; end
  def from              ; @obj.from_sobject.content ; end
  def relation          ; @obj.category             ; end
  def position          ; @obj.position             ; end
  def extra_info        ; @obj.extra_info           ; end
end

class TagDrop < BagelDrop
  def title             ; @obj.name                 ; end
  def parent            ; @obj.parent               ; end
end

class WebsiteDrop < BagelDrop
  def title             ; @obj.name                 ; end
  def domain            ; @obj.domain               ; end
end
