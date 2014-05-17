describe('Quill', ->
  beforeEach( ->
    @container = $('#editor-container').html('
      <div>
        <p>0123</p>
        <p>5678</p>
      </div>
    ').get(0)
    @quill = new Quill(@container.firstChild)
  )

  describe('constructor', ->
    it('string container', ->
      @container.innerHTML = '<div id="target"></div>'
      quill = new Quill('#target')
      expect(quill.editor.iframeContainer).toEqual(@container.firstChild)
    )

    it('invalid container', ->
      expect( =>
        @quill = new Quill('.none')
      ).toThrow(new Error('Invalid Quill container'))
    )
  )

  describe('modules', ->
    it('addContainer()', ->
      @quill.addContainer('test-container', true)
      expect(@quill.root.parentNode.querySelector('.test-container')).toEqual(@quill.root.parentNode.firstChild)
    )

    it('addModule()', ->
      obj =
        before: ->
        after: ->
      spyOn(obj, 'before')
      spyOn(obj, 'after')
      expect(@quill.getModule('toolbar')).toBe(undefined)
      @quill.onModuleLoad('toolbar', obj.before)
      @quill.addModule('toolbar', { container: '#toolbar-container' })
      expect(@quill.getModule('toolbar')).not.toBe(null)
      expect(obj.before).toHaveBeenCalled()
      @quill.onModuleLoad('toolbar', obj.after)
      expect(obj.after).toHaveBeenCalled()
    )

    it('addModule() nonexistent', ->
      expect( =>
        @quill.addModule('nonexistent')
      ).toThrow(new Error("Cannot load nonexistent module. Are you sure you included it?"))
    )
  )

  describe('manipulation', ->
    it('deleteText()', ->
      @quill.deleteText(2, 3)
      expect(@quill.root).toEqualHTML('<p>013</p><p>5678</p>', true)
    )

    it('formatLine()', ->
      @quill.formatLine(4, 6, 'align', 'right')
      expect(@quill.root).toEqualHTML('
        <p style="text-align: right;">0123</p>
        <p style="text-align: right;">5678</p>
      ', true)
    )

    it('formatText()', ->
      @quill.formatText(2, 4, 'bold', true)
      expect(@quill.root).toEqualHTML('<p>01<b>23</b></p><p>5678</p>', true)
      @quill.formatText(2, 4, 'bold', false)
      expect(@quill.root).toEqualHTML('<p>0123</p><p>5678</p>', true)
      expect(@quill.getContents(0, 4)).toEqualDelta(Tandem.Delta.makeInsertDelta(0, 0, '0123'))
    )

    it('formatText() default style', ->
      html = @quill.root.innerHTML
      @quill.formatText(2, 4, 'size', '13px')
      expect(@quill.root).toEqualHTML(html)
    )

    it('insertEmbed()', ->
      @quill.insertEmbed(2, 'image', 'http://quilljs.com/images/cloud.png')
      expect(@quill.root).toEqualHTML('<p>01<img src="http://quilljs.com/images/cloud.png">23</p><p>5678</p>', true)
    )

    it('insertText()', ->
      @quill.insertText(2, 'A')
      expect(@quill.root).toEqualHTML('<p>01A23</p><p>5678</p>', true)
    )

    it('setContents() with delta', ->
      @quill.setContents({
        startLength: 0
        endLength: 1
        ops: [{ value: 'A', attributes: { bold: true } }]
      })
      expect(@quill.root).toEqualHTML('<p><b>A</b></p>', true)
    )

    it('setContents() with ops', ->
      @quill.setContents([{ value: 'A', attributes: { bold: true } }])
      expect(@quill.root).toEqualHTML('<p><b>A</b></p>', true)
    )

    it('setHTML()', ->
      @quill.setHTML('<p>A</p>')
      expect(@quill.root).toEqualHTML('<p>A</p>', true)
    )

    it('updateContents()', ->
      @quill.updateContents(Tandem.Delta.makeInsertDelta(10, 2, 'A'))
      expect(@quill.root).toEqualHTML('<p>01A23</p><p>5678</p>', true)
    )
  )

  describe('retrievals', ->
    it('getContents() all', ->
      expect(@quill.getContents()).toEqualDelta(Tandem.Delta.makeInsertDelta(0, 0, '0123\n5678\n'))
    )

    it('getContents() partial', ->
      expect(@quill.getContents(2, 7)).toEqualDelta(Tandem.Delta.makeInsertDelta(0, 0, '23\n56'))
    )

    it('getHTML()', ->
      expect(@quill.getHTML()).toEqualHTML('<p>0123</p><p>5678</p>', true)
    )

    it('getLength()', ->
      expect(@quill.getLength()).toEqual(10)
    )

    it('getText()', ->
      expect(@quill.getText()).toEqual('0123\n5678\n')
    )
  )

  describe('selection', ->
    it('get/set range', ->
      @quill.setSelection(1, 2)
      range = @quill.getSelection()
      expect(range).not.toBe(null)
      expect(range.start).toEqual(1)
      expect(range.end).toEqual(2)
    )

    it('get/set index range', ->
      @quill.setSelection(new Quill.Lib.Range(2, 3))
      range = @quill.getSelection()
      expect(range).not.toBe(null)
      expect(range.start).toEqual(2)
      expect(range.end).toEqual(3)
    )

    it('get/set null', ->
      @quill.setSelection(1, 2)
      expect(range).not.toBe(null)
      @quill.setSelection(null)
      range = @quill.getSelection()
      expect(range).toBe(null)
    )
  )

  describe('_buildParams()', ->
    tests =
      'index range string formats'  : [1, 3, 'bold', true]
      'index range object formats'  : [1, 3, { bold: true }]
      'object range string formats' : [new Quill.Lib.Range(1, 3), 'bold', true]
      'object range object formats' : [new Quill.Lib.Range(1, 3), { bold: true }]

    _.each(tests, (args, name) ->
      it(name, ->
        [start, end, formats, source] = @quill._buildParams(args...)
        expect(start).toEqual(1)
        expect(end).toEqual(3)
        expect(formats).toEqual({ bold: true })
      )
    )

    it('source override', ->
      [start, end, formats, source] = @quill._buildParams(1, 2, {}, 'silent')
      expect(source).toEqual('silent')
    )
  )
)
