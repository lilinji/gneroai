#!/usr/bin/env python3
"""
Markdown图片和GIF提取工具
从给定的markdown文件中提取所有图片和GIF文件并复制到指定目录
"""

import os
import re
import shutil
import argparse
import logging
from pathlib import Path
from typing import List, Set, Tuple
from urllib.parse import unquote, urlparse

class MarkdownImageExtractor:
    """Markdown图片提取器"""
    
    def __init__(self, target_dir: str, verbose: bool = False):
        self.target_dir = Path(target_dir)
        self.verbose = verbose
        
        # 支持的图片扩展名
        self.image_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.svg', '.bmp', '.tiff', '.webp'}
        
        # 设置日志
        logging.basicConfig(
            level=logging.DEBUG if verbose else logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
    def ensure_target_dir(self) -> None:
        """确保目标目录存在"""
        self.target_dir.mkdir(parents=True, exist_ok=True)
        self.logger.info(f"目标目录: {self.target_dir}")
    
    def find_markdown_files(self, root_path: str) -> List[Path]:
        """查找所有markdown文件"""
        md_files = []
        root = Path(root_path)
        
        if root.is_file() and root.suffix.lower() in ['.md', '.markdown']:
            return [root]
            
        for ext in ['.md', '.markdown']:
            md_files.extend(root.rglob(f'*{ext}'))
            md_files.extend(root.rglob(f'*{ext.upper()}'))
            
        self.logger.info(f"找到 {len(md_files)} 个markdown文件")
        return md_files
    
    def extract_image_paths(self, md_content: str, md_file_path: Path) -> List[str]:
        """提取markdown内容中的图片路径"""
        image_paths = []
        
        # Markdown图片语法: ![alt](path)
        md_pattern = r'!\[([^\]]*)\]\(([^)]+)\)'
        md_matches = re.findall(md_pattern, md_content)
        for alt, path in md_matches:
            image_paths.append(path)
            
        # HTML img标签: <img src="path" ...>
        img_pattern = r'<img[^>]+src=["\']([^"\']+)["\'][^>]*>'
        img_matches = re.findall(img_pattern, md_content, re.IGNORECASE)
        image_paths.extend(img_matches)
        
        # 过滤只保留GIF和图片文件
        filtered_paths = []
        for path in image_paths:
            if self.is_image_path(path):
                filtered_paths.append(path)
                self.logger.debug(f"找到图片: {path}")
                
        return list(set(filtered_paths))  # 去重
    
    def is_image_path(self, path: str) -> bool:
        """判断是否为图片或GIF文件"""
        if not path:
            return False
            
        # 处理URL编码
        decoded_path = unquote(path)
        
        # 排除网络URL
        if decoded_path.startswith(('http://', 'https://', '//')):
            return False
            
        # 获取文件扩展名
        parsed = urlparse(decoded_path)
        file_path = parsed.path
        extension = Path(file_path).suffix.lower()
        
        return extension in self.image_extensions
    
    def resolve_relative_path(self, path: str, md_file_path: Path) -> Path:
        """解析相对路径"""
        # 处理URL编码
        decoded_path = unquote(path)
        
        # 移除URL查询参数和片段
        parsed = urlparse(decoded_path)
        file_path = parsed.path
        
        # 如果是绝对路径，直接返回；否则相对于markdown文件路径
        if os.path.isabs(file_path):
            source_path = Path(file_path)
        else:
            source_path = md_file_path.parent / file_path
            
        return source_path.resolve()
    
    def copy_images_to_target(self, image_paths: List[str], md_file_path: Path) -> Tuple[int, List[str]]:
        """将图片复制到目标目录"""
        copied_count = 0
        failed_list = []
        
        for image_path in image_paths:
            try:
                source_path = self.resolve_relative_path(image_path, md_file_path)
                
                if not source_path.exists():
                    self.logger.warning(f"文件不存在: {source_path}")
                    failed_list.append(str(source_path))
                    continue
                
                # 创建目标子目录结构
                relative_dir = source_path.parent.name
                if relative_dir and relative_dir.lower() != os.path.basename(source_path.parent):
                    target_subdir = self.target_dir / relative_dir
                else:
                    target_subdir = self.target_dir
                target_subdir.mkdir(parents=True, exist_ok=True)
                
                # 生成目标文件名（避免重复）  
                filename = source_path.name
                target_path = target_subdir / filename
                
                counter = 1
                while target_path.exists():
                    name_without_ext = source_path.stem
                    extension = source_path.suffix
                    target_path = target_subdir / f"{name_without_ext}_{counter}{extension}"
                    counter += 1
                
                # 复制文件
                shutil.copy2(source_path, target_path)
                copied_count += 1
                
                self.logger.info(f"已复制: {source_path.name} -> {target_path}")
                
            except Exception as e:
                self.logger.error(f"复制失败 {image_path}: {str(e)}")
                failed_list.append(image_path)
        
        return copied_count, failed_list
    
    def process_markdown_file(self, md_file_path: Path) -> Tuple[int, List[str]]:
        """处理单个markdown文件"""
        try:
            with open(md_file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            image_paths = self.extract_image_paths(content, md_file_path)
            if not image_paths:
                self.logger.info(f"文件中没有找到图片: {md_file_path}")
                return 0, []
                
            self.logger.info(f"在 {md_file_path} 中找到 {len(image_paths)} 张图片")
            return self.copy_images_to_target(image_paths, md_file_path)
            
        except Exception as e:
            self.logger.error(f"处理文件失败 {md_file_path}: {str(e)}")
            return 0, [str(md_file_path)]
    
    def traverse_and_process(self, source_path: str) -> Tuple[int, int, List[str]]:
        """遍历并处理所有markdown文件"""
        self.ensure_target_dir()
        
        md_files = self.find_markdown_files(source_path)
        if not md_files:
            self.logger.warning("没有找到markdown文件")
            return 0, 0, []
            
        total_copied = 0
        total_files_processed = 0
        total_failed = []
        
        for md_file in md_files:
            self.logger.info(f"处理文件: {md_file}")
            copied, failed = self.process_markdown_file(md_file)
            total_copied += copied
            total_files_processed += 1 if copied > 0 or failed else total_files_processed
            total_failed.extend(failed)
        
        return total_copied, len(md_files), total_failed

def main():
    parser = argparse.ArgumentParser(
        description='从Markdown文件中提取图片和GIF到指定目录',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
示例用法:
  %(prog)s markdown文件路径 目标目录
  %(prog)s /path/to/doc.md /output/images/
  %(prog)s /path/to/docs/dir /output/images/ -v
  %(prog)s *.doc.md /output/images/ -v
        '''
    )
    
    parser.add_argument('source', help='markdown文件路径或目录路径')
    parser.add_argument('target', help='目标图片输出目录')
    parser.add_argument('-v', '--verbose', action='store_true', 
                       help='显示详细输出')
    parser.add_argument('-q', '--quiet', action='store_true', 
                       help='只显示错误信息')
    
    args = parser.parse_args()
    
    # 处理多个文件的情况
    source_paths = [args.source]
    if '*' in args.source or '?' in args.source:
        # 通配符模式
        import glob
        source_paths = glob.glob(args.source, recursive=True)
    
    extractor = MarkdownImageExtractor(args.target, verbose=args.verbose)
    
    if args.quiet:
        extractor.logger.setLevel(logging.ERROR)
    
    total_copied = 0
    total_files = 0
    total_failed = []
    
    for source_path in source_paths:
        if os.path.exists(source_path):
            copied, files_processed, failed = extractor.traverse_and_process(source_path)
            total_copied += copied
            total_files += files_processed
            total_failed.extend(failed)
        else:
            print(f"错误: 路径不存在: {source_path}")
    
    
    # 打印总结
    print(f"\n" + "="*50)
    print("处理完成")
    print("="*50)
    print(f"处理markdown文件: {total_files} 个")
    print(f"成功复制图片: {total_copied} 个")
    if total_failed:
        print(f"失败项目: {len(total_failed)} 个")
        for fail in total_failed[:5]:
            print(f"  - {fail}")
        if len(total_failed) > 5:
            print(f"  ... 还有 {len(total_failed) - 5} 项未列出")
    print("="*50)
    
    return 0 if not total_failed else 1

if __name__ == "__main__":
    exit(main())