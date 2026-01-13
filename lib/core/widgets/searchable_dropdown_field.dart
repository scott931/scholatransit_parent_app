import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

/// A searchable dropdown field that allows both selecting from a list
/// and entering custom text
class SearchableDropdownField<T> extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final List<T> options;
  final String Function(T) getDisplayText;
  final String? Function(String?)? validator;
  final Future<List<T>>? Function(String)? onSearch;
  final bool isLoading;
  final String? errorText;
  final void Function(T)? onSelected; // Callback when an option is selected

  const SearchableDropdownField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.icon,
    required this.options,
    required this.getDisplayText,
    this.validator,
    this.onSearch,
    this.isLoading = false,
    this.errorText,
    this.onSelected,
  });

  @override
  State<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T>
    extends State<SearchableDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  List<T> _filteredOptions = [];
  bool _showDropdown = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _filteredOptions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.toLowerCase();
    
    final onSearch = widget.onSearch;
    if (onSearch != null) {
      // Use async search function
      _isSearching = true;
      if (mounted) {
        setState(() {});
      }
      final searchFuture = onSearch(query);
      if (searchFuture != null) {
        searchFuture.then((results) {
          if (mounted) {
            setState(() {
              _filteredOptions = results;
              _isSearching = false;
            });
            if (_focusNode.hasFocus) {
              if (_filteredOptions.isNotEmpty) {
                _showOverlay();
              } else {
                _removeOverlay();
              }
            }
          }
        });
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    } else {
      // Filter local options
      if (mounted) {
        setState(() {
          _filteredOptions = widget.options
              .where((option) =>
                  widget.getDisplayText(option).toLowerCase().contains(query))
              .toList();
        });
        if (_focusNode.hasFocus) {
          if (_filteredOptions.isNotEmpty) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      }
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showDropdown = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showDropdown = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: 200.h,
              ),
              child: _filteredOptions.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        widget.isLoading || _isSearching
                            ? 'Loading...'
                            : 'No options found. You can type your own.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textPrimary.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredOptions.length,
                      itemBuilder: (context, index) {
                        final option = _filteredOptions[index];
                        return InkWell(
                          onTap: () {
                            if (mounted) {
                              widget.controller.text =
                                  widget.getDisplayText(option);
                              // Call onSelected callback if provided
                              if (widget.onSelected != null) {
                                widget.onSelected!(option);
                              }
                              _removeOverlay();
                              _focusNode.unfocus();
                            }
                          },
                          hoverColor: AppTheme.surfaceBlue,
                          splashColor: AppTheme.surfaceBlueLight,
                          highlightColor: AppTheme.surfaceBlue,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            child: Text(
                              widget.getDisplayText(option),
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
          prefixIcon: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: Colors.grey[600],
                )
              : null,
          suffixIcon: widget.isLoading || _isSearching
              ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 20.w,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {
                          _filteredOptions = widget.options;
                        });
                      },
                    )
                  : Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: AppTheme.errorColor,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: AppTheme.errorColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          errorText: widget.errorText,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
        onTap: () {
          if (_filteredOptions.isNotEmpty) {
            _showOverlay();
          }
        },
        onEditingComplete: () {
          _removeOverlay();
          _focusNode.unfocus();
        },
      ),
    );
  }
}
